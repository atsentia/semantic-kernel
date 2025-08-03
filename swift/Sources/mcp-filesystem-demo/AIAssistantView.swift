//
// AI Assistant View
// Chat interface with Semantic Kernel integration
//

import SwiftUI

struct AIAssistantView: View {
    @ObservedObject var viewModel: MCPFilesystemViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("AI Assistant")
                .font(.title2)
                .padding()
            
            Divider()
            
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if viewModel.chatMessages.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "brain")
                                    .font(.system(size: 48))
                                    .foregroundColor(.blue)
                                
                                Text("AI Filesystem Assistant")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("Ask me about files, directories, or filesystem operations in your current location.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Example questions:")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    
                                    Text("• What files are in this directory?")
                                    Text("• Can you help me organize these files?")
                                    Text("• What's the largest file here?")
                                    Text("• Show me all text files")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(viewModel.chatMessages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isWaitingForAI {
                                HStack {
                                    Image(systemName: "brain")
                                        .foregroundColor(.blue)
                                    
                                    HStack(spacing: 4) {
                                        ForEach(0..<3) { index in
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 8, height: 8)
                                                .scaleEffect(viewModel.isWaitingForAI ? 1.0 : 0.5)
                                                .animation(
                                                    Animation.easeInOut(duration: 0.6)
                                                        .repeatForever()
                                                        .delay(Double(index) * 0.2),
                                                    value: viewModel.isWaitingForAI
                                                )
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.chatMessages.count) { _ in
                    if let lastMessage = viewModel.chatMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Ask about files and directories...", text: $viewModel.userInput)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }
                    .disabled(viewModel.isWaitingForAI)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSendMessage ? .blue : .gray)
                }
                .disabled(!canSendMessage)
            }
            .padding()
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private var canSendMessage: Bool {
        !viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !viewModel.isWaitingForAI
    }
    
    private func sendMessage() {
        guard canSendMessage else { return }
        viewModel.sendMessage(viewModel.userInput)
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity * 0.8, alignment: .trailing)
                
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            } else {
                Image(systemName: "brain")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity * 0.8, alignment: .leading)
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Removed custom corner radius implementation since we're using simple cornerRadius now

#Preview {
    AIAssistantView(viewModel: MCPFilesystemViewModel())
        .frame(width: 500, height: 600)
}