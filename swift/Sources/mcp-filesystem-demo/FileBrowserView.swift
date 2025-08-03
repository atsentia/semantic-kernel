//
// File Browser View
// Interactive file system browser with MCP operations
//

import SwiftUI
import MCPShared

struct FileBrowserView: View {
    @ObservedObject var viewModel: MCPFilesystemViewModel
    @State private var selectedFile: FileItem?
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Current Path Header
            HStack {
                Button(action: viewModel.navigateUp) {
                    Image(systemName: "arrow.up")
                }
                .disabled(!viewModel.canNavigateUp)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(viewModel.currentPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                }
                
                Spacer()
                
                Menu {
                    Button("New Folder", action: { showingNewFolderAlert = true })
                    Button("Refresh", action: viewModel.refreshCurrentDirectory)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // File List
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.files.isEmpty {
                VStack {
                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Empty Directory")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.files, id: \.id, selection: $selectedFile) { file in
                    FileRowView(file: file) {
                        if file.type == .directory {
                            viewModel.navigateToDirectory(file.path)
                        } else {
                            selectedFile = file
                            viewModel.selectFile(file)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            
            // Status Bar
            HStack {
                Text("\(viewModel.files.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let error = viewModel.lastError {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder Name", text: $newFolderName)
            Button("Create") {
                if !newFolderName.isEmpty {
                    viewModel.createDirectory(named: newFolderName)
                    newFolderName = ""
                }
            }
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
        } message: {
            Text("Enter a name for the new folder")
        }
    }
}

struct FileRowView: View {
    let file: FileItem
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(file.type.icon)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if file.type == .file {
                        Text(formatFileSize(file.size))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(formatDate(file.modified))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onSelect()
        }
    }
    
    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    FileBrowserView(viewModel: MCPFilesystemViewModel())
        .frame(width: 300, height: 400)
}