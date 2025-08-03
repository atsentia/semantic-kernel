//
// Main Content View for iOS Semantic Kernel Demo
// Chat interface with AI assistant
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Plugin Header Section
                PluginHeaderView { suggestion in
                    viewModel.inputText = suggestion
                    viewModel.sendMessage()
                }
                .padding(.top, 8)
                
                Divider()
                
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isWaitingForResponse {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input Area
                MessageInputView(
                    text: $viewModel.inputText,
                    isLoading: viewModel.isWaitingForResponse,
                    onSend: {
                        viewModel.sendMessage()
                    }
                )
            }
            .navigationTitle("SK Demo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") {
                        viewModel.clearChat()
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
            }
        }
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
        .onAppear {
            viewModel.initializeKernel()
        }
    }
}

#Preview {
    ContentView()
}