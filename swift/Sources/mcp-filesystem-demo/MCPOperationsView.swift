//
// MCP Operations View
// Interface for testing MCP filesystem operations
//

import SwiftUI
import MCPShared

struct MCPOperationsView: View {
    @ObservedObject var viewModel: MCPFilesystemViewModel
    @State private var selectedOperation: MCPOperation = .listDirectory
    @State private var operationParameters: [String: String] = [:]
    @State private var showingFileDialog = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MCP Operations")
                .font(.title2)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Operation Selector
                    GroupBox("Select Operation") {
                        Picker("Operation", selection: $selectedOperation) {
                            ForEach(MCPOperation.allCases, id: \.self) { operation in
                                Text(operation.displayName).tag(operation)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedOperation) { _ in
                            updateParametersForOperation()
                        }
                    }
                    
                    // Operation Parameters
                    GroupBox("Parameters") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(parametersForOperation(selectedOperation), id: \.key) { param in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(param.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        if param.required {
                                            Text("*")
                                                .foregroundColor(.red)
                                        }
                                        
                                        Spacer()
                                        
                                        if param.key == "path" {
                                            Button("Browse") {
                                                showingFileDialog = true
                                            }
                                            .font(.caption)
                                        }
                                    }
                                    
                                    if param.key == "content" {
                                        TextEditor(text: Binding(
                                            get: { operationParameters[param.key, default: ""] },
                                            set: { operationParameters[param.key] = $0 }
                                        ))
                                        .font(.system(.body, design: .monospaced))
                                        .frame(minHeight: 100)
                                        .border(Color.gray.opacity(0.3))
                                    } else {
                                        TextField(param.placeholder, text: Binding(
                                            get: { operationParameters[param.key, default: ""] },
                                            set: { operationParameters[param.key] = $0 }
                                        ))
                                        .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Execute Button
                    Button(action: executeOperation) {
                        HStack {
                            if viewModel.isPerformingOperation {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isPerformingOperation ? "Executing..." : "Execute Operation")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isPerformingOperation || !canExecuteOperation())
                    
                    // Result Display
                    GroupBox("Result") {
                        ScrollView {
                            if viewModel.mcpOperationResult.isEmpty && !viewModel.isPerformingOperation {
                                Text("No operation executed yet")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                Text(viewModel.mcpOperationResult)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                        .frame(minHeight: 200)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            updateParametersForOperation()
        }
        .fileImporter(
            isPresented: $showingFileDialog,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    operationParameters["path"] = url.path
                }
            case .failure(let error):
                print("File selection error: \(error)")
            }
        }
    }
    
    private func updateParametersForOperation() {
        operationParameters.removeAll()
        
        // Set default values based on current context
        switch selectedOperation {
        case .listDirectory:
            operationParameters["path"] = viewModel.currentPath
        case .readFile, .getFileInfo:
            if let selectedFile = viewModel.selectedFile {
                operationParameters["path"] = selectedFile.path
            }
        case .writeFile:
            if let selectedFile = viewModel.selectedFile, selectedFile.type == .file {
                operationParameters["path"] = selectedFile.path
            }
        case .createDirectory:
            operationParameters["path"] = viewModel.currentPath + "/NewFolder"
        case .searchFiles:
            operationParameters["directory"] = viewModel.currentPath
            operationParameters["pattern"] = "*.txt"
            operationParameters["recursive"] = "false"
        }
    }
    
    private func executeOperation() {
        viewModel.performMCPOperation(selectedOperation, parameters: operationParameters)
    }
    
    private func canExecuteOperation() -> Bool {
        let requiredParams = parametersForOperation(selectedOperation).filter { $0.required }
        return requiredParams.allSatisfy { param in
            let value = operationParameters[param.key, default: ""]
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func parametersForOperation(_ operation: MCPOperation) -> [OperationParameter] {
        switch operation {
        case .listDirectory:
            return [
                OperationParameter(key: "path", displayName: "Directory Path", placeholder: "Path to directory", required: false)
            ]
        case .readFile:
            return [
                OperationParameter(key: "path", displayName: "File Path", placeholder: "Path to file", required: true)
            ]
        case .writeFile:
            return [
                OperationParameter(key: "path", displayName: "File Path", placeholder: "Path to file", required: true),
                OperationParameter(key: "content", displayName: "Content", placeholder: "File content", required: true)
            ]
        case .createDirectory:
            return [
                OperationParameter(key: "path", displayName: "Directory Path", placeholder: "Path to new directory", required: true)
            ]
        case .getFileInfo:
            return [
                OperationParameter(key: "path", displayName: "File/Directory Path", placeholder: "Path to item", required: true)
            ]
        case .searchFiles:
            return [
                OperationParameter(key: "directory", displayName: "Search Directory", placeholder: "Directory to search", required: false),
                OperationParameter(key: "pattern", displayName: "Pattern", placeholder: "e.g., *.txt", required: true),
                OperationParameter(key: "recursive", displayName: "Recursive", placeholder: "true or false", required: false)
            ]
        }
    }
}

struct OperationParameter {
    let key: String
    let displayName: String
    let placeholder: String
    let required: Bool
}

#Preview {
    MCPOperationsView(viewModel: MCPFilesystemViewModel())
        .frame(width: 500, height: 600)
}