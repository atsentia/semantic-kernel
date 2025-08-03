//
// Message Input View for visionOS
// Spatial text input with enhanced visionOS interactions
//

import SwiftUI

struct VisionOSMessageInputView: View {
    let onSend: (String) -> Void
    
    @State private var messageText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Microphone button for spatial input
            Button(action: {
                // Voice input placeholder
                messageText = "Voice input not yet implemented"
                isTextFieldFocused = true
            }) {
                Image(systemName: "mic.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(.blue.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            
            // Text input field with spatial styling
            HStack {
                TextField("Ask the Spatial AI anything...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .lineLimit(1...4)
                    .onSubmit {
                        sendMessage()
                    }
                
                if !messageText.isEmpty {
                    Button(action: {
                        messageText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            // Send button with spatial glow
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(messageText.isEmpty ? .secondary : .white)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(
                        messageText.isEmpty ? Color.gray.opacity(0.3) : Color.blue,
                        in: Circle()
                    )
                    .overlay(
                        Circle()
                            .stroke(messageText.isEmpty ? .clear : .blue.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(messageText.isEmpty)
            .hoverEffect(.highlight)
            .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        onSend(trimmedMessage)
        messageText = ""
        isTextFieldFocused = false
    }
}

#Preview {
    VStack {
        Spacer()
        VisionOSMessageInputView { message in
            print("Message sent: \(message)")
        }
    }
    .padding()
}