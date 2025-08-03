//
// MCP Filesystem Service
// Reusable filesystem operations with security controls
//

import Foundation

// MARK: - Security Manager

public class MCPSecurityManager {
    private var allowedPaths: Set<String> = []
    private let maxFileSize: Int = 10 * 1024 * 1024 // 10MB limit
    private let maxDirectoryDepth: Int = 10
    
    public init() {
        setupDefaultPaths()
    }
    
    private func setupDefaultPaths() {
        let currentDir = FileManager.default.currentDirectoryPath
        allowedPaths.insert(currentDir)
        
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                       in: .userDomainMask).first?.path {
            allowedPaths.insert(documentsPath)
        }
        
        if let desktopPath = FileManager.default.urls(for: .desktopDirectory, 
                                                     in: .userDomainMask).first?.path {
            allowedPaths.insert(desktopPath)
        }
        
        let tempPath = NSTemporaryDirectory()
        allowedPaths.insert(tempPath)
    }
    
    public func isPathAllowed(_ path: String) -> Bool {
        let normalizedPath = URL(fileURLWithPath: path).standardized.path
        
        for allowedPath in allowedPaths {
            let normalizedAllowed = URL(fileURLWithPath: allowedPath).standardized.path
            if normalizedPath.hasPrefix(normalizedAllowed) {
                return true
            }
        }
        
        return false
    }
    
    public func validateFileSize(_ path: String) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let fileSize = attributes[.size] as? Int {
                return fileSize <= maxFileSize
            }
        } catch {
            return false
        }
        return true
    }
    
    public func validateDirectoryDepth(_ path: String) -> Bool {
        let components = URL(fileURLWithPath: path).pathComponents
        return components.count <= maxDirectoryDepth
    }
    
    public func sanitizePath(_ path: String) -> String? {
        let sanitized = path
            .replacingOccurrences(of: "../", with: "")
            .replacingOccurrences(of: "./", with: "")
            .replacingOccurrences(of: "//", with: "/")
        
        return sanitized.isEmpty ? nil : sanitized
    }
    
    public func getAllowedPaths() -> [String] {
        return Array(allowedPaths).sorted()
    }
}

// MARK: - File System Operations

public struct FileItem: Codable, Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let path: String
    public let type: FileType
    public let size: Int
    public let modified: Date
    
    public enum FileType: String, Codable, CaseIterable {
        case file = "file"
        case directory = "directory"
        
        public var icon: String {
            switch self {
            case .file: return "📄"
            case .directory: return "📁"
            }
        }
    }
    
    public init(name: String, path: String, type: FileType, size: Int, modified: Date) {
        self.name = name
        self.path = path
        self.type = type
        self.size = size
        self.modified = modified
    }
}

public enum MCPFilesystemError: Error, LocalizedError {
    case pathNotAllowed
    case invalidPath
    case fileTooLarge
    case directoryTooDeep
    case fileNotFound
    case accessDenied
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .pathNotAllowed:
            return "Path is not in allowed directories"
        case .invalidPath:
            return "Invalid or unsafe path"
        case .fileTooLarge:
            return "File is too large (max 10MB)"
        case .directoryTooDeep:
            return "Directory structure too deep"
        case .fileNotFound:
            return "File or directory not found"
        case .accessDenied:
            return "Access denied"
        case .unknown(let message):
            return message
        }
    }
}

public class MCPFilesystemService {
    private let securityManager = MCPSecurityManager()
    
    public init() {}
    
    // MARK: - File Operations
    
    public func readFile(path: String) throws -> String {
        guard let sanitizedPath = securityManager.sanitizePath(path) else {
            throw MCPFilesystemError.invalidPath
        }
        
        guard securityManager.isPathAllowed(sanitizedPath) else {
            throw MCPFilesystemError.pathNotAllowed
        }
        
        guard securityManager.validateFileSize(sanitizedPath) else {
            throw MCPFilesystemError.fileTooLarge
        }
        
        do {
            return try String(contentsOfFile: sanitizedPath, encoding: .utf8)
        } catch {
            throw MCPFilesystemError.unknown(error.localizedDescription)
        }
    }
    
    public func writeFile(path: String, content: String) throws {
        guard let sanitizedPath = securityManager.sanitizePath(path) else {
            throw MCPFilesystemError.invalidPath
        }
        
        guard securityManager.isPathAllowed(sanitizedPath) else {
            throw MCPFilesystemError.pathNotAllowed
        }
        
        let parentDirectory = URL(fileURLWithPath: sanitizedPath).deletingLastPathComponent().path
        do {
            try FileManager.default.createDirectory(atPath: parentDirectory, 
                                                   withIntermediateDirectories: true, 
                                                   attributes: nil)
            try content.write(toFile: sanitizedPath, atomically: true, encoding: .utf8)
        } catch {
            throw MCPFilesystemError.unknown(error.localizedDescription)
        }
    }
    
    public func listDirectory(path: String? = nil) throws -> [FileItem] {
        let directoryPath = path ?? FileManager.default.currentDirectoryPath
        
        guard let sanitizedPath = securityManager.sanitizePath(directoryPath) else {
            throw MCPFilesystemError.invalidPath
        }
        
        guard securityManager.isPathAllowed(sanitizedPath) else {
            throw MCPFilesystemError.pathNotAllowed
        }
        
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: sanitizedPath)
            var fileItems: [FileItem] = []
            
            for item in items.sorted() {
                let itemPath = URL(fileURLWithPath: sanitizedPath).appendingPathComponent(item).path
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: itemPath)
                    let isDirectory = attributes[.type] as? FileAttributeType == .typeDirectory
                    let size = attributes[.size] as? Int ?? 0
                    let modificationDate = attributes[.modificationDate] as? Date ?? Date()
                    
                    let fileItem = FileItem(
                        name: item,
                        path: itemPath,
                        type: isDirectory ? .directory : .file,
                        size: size,
                        modified: modificationDate
                    )
                    fileItems.append(fileItem)
                } catch {
                    continue
                }
            }
            
            return fileItems
        } catch {
            throw MCPFilesystemError.unknown(error.localizedDescription)
        }
    }
    
    public func createDirectory(path: String) throws {
        guard let sanitizedPath = securityManager.sanitizePath(path) else {
            throw MCPFilesystemError.invalidPath
        }
        
        guard securityManager.isPathAllowed(sanitizedPath) else {
            throw MCPFilesystemError.pathNotAllowed
        }
        
        do {
            try FileManager.default.createDirectory(atPath: sanitizedPath, 
                                                   withIntermediateDirectories: true, 
                                                   attributes: nil)
        } catch {
            throw MCPFilesystemError.unknown(error.localizedDescription)
        }
    }
    
    public func getFileInfo(path: String) throws -> FileItem {
        guard let sanitizedPath = securityManager.sanitizePath(path) else {
            throw MCPFilesystemError.invalidPath
        }
        
        guard securityManager.isPathAllowed(sanitizedPath) else {
            throw MCPFilesystemError.pathNotAllowed
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: sanitizedPath)
            let isDirectory = attributes[.type] as? FileAttributeType == .typeDirectory
            let size = attributes[.size] as? Int ?? 0
            let modificationDate = attributes[.modificationDate] as? Date ?? Date()
            let fileName = URL(fileURLWithPath: sanitizedPath).lastPathComponent
            
            return FileItem(
                name: fileName,
                path: sanitizedPath,
                type: isDirectory ? .directory : .file,
                size: size,
                modified: modificationDate
            )
        } catch {
            throw MCPFilesystemError.unknown(error.localizedDescription)
        }
    }
    
    public func searchFiles(directory: String? = nil, pattern: String, recursive: Bool = false) throws -> [FileItem] {
        let searchDirectory = directory ?? FileManager.default.currentDirectoryPath
        
        guard let sanitizedDirectory = securityManager.sanitizePath(searchDirectory) else {
            throw MCPFilesystemError.invalidPath
        }
        
        guard securityManager.isPathAllowed(sanitizedDirectory) else {
            throw MCPFilesystemError.pathNotAllowed
        }
        
        var matchingFiles: [FileItem] = []
        
        func searchInDirectory(_ dir: String, depth: Int = 0) {
            guard depth < 5 else { return }
            
            do {
                let items = try FileManager.default.contentsOfDirectory(atPath: dir)
                for item in items {
                    let itemPath = URL(fileURLWithPath: dir).appendingPathComponent(item).path
                    
                    if item.matches(pattern: pattern) {
                        if let fileItem = try? getFileInfo(path: itemPath) {
                            matchingFiles.append(fileItem)
                        }
                    }
                    
                    if recursive {
                        var isDir: ObjCBool = false
                        if FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir) && isDir.boolValue {
                            searchInDirectory(itemPath, depth: depth + 1)
                        }
                    }
                }
            } catch {
                return
            }
        }
        
        searchInDirectory(sanitizedDirectory)
        return matchingFiles
    }
    
    // MARK: - Utility Methods
    
    public func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    public func getAllowedPaths() -> [String] {
        return securityManager.getAllowedPaths()
    }
}

// MARK: - Extensions

extension String {
    func matches(pattern: String) -> Bool {
        let regex = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")
        
        do {
            let nsRegex = try NSRegularExpression(pattern: "^" + regex + "$", options: [.caseInsensitive])
            let range = NSRange(location: 0, length: self.count)
            return nsRegex.firstMatch(in: self, options: [], range: range) != nil
        } catch {
            return self.lowercased().contains(pattern.lowercased())
        }
    }
}