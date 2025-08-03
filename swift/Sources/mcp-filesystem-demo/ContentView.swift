//
// Content View for MCP Filesystem Demo
// Main UI layout with file browser and AI chat interface
//

import SwiftUI
import MCPShared

struct ContentView: View {
    @StateObject private var viewModel = MCPFilesystemViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        HSplitView {
            // Left Panel - File Browser
            VStack(alignment: .leading, spacing: 0) {
                Text("File Browser")
                    .font(.headline)
                    .padding()
                
                Divider()
                
                FileBrowserView(viewModel: viewModel)
                    .frame(minWidth: 300)
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            // Right Panel - MCP & AI Interface
            VStack(alignment: .leading, spacing: 0) {
                TabView(selection: $selectedTab) {
                    MCPOperationsView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "gear")
                            Text("MCP Operations")
                        }
                        .tag(0)
                    
                    AIAssistantView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "brain")
                            Text("AI Assistant")
                        }
                        .tag(1)
                }
                .frame(minWidth: 400)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .navigationTitle("MCP Filesystem Demo")
        .onAppear {
            viewModel.loadInitialDirectory()
        }
    }
}

#Preview {
    ContentView()
}