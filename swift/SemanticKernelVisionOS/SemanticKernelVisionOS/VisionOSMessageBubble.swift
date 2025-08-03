//
// Message Bubble View for visionOS
// Enhanced chat bubbles with spatial depth and materials
//

import SwiftUI

struct VisionOSMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text(message.content)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "brain.head.profile.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                            .padding(.leading, 4)
                        
                        Text(message.content)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.purple.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
                
                Spacer(minLength: 50)
            }
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.3), value: message.id)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        VisionOSMessageBubble(message: ChatMessage(
            content: "Hello! This is a user message in visionOS spatial computing.",
            isUser: true,
            timestamp: Date()
        ))
        
        VisionOSMessageBubble(message: ChatMessage(
            content: "🤖 Hello! This is an AI response with spatial context. I can help you with math, text processing, and time-related queries using the Semantic Kernel plugins.",
            isUser: false,
            timestamp: Date()
        ))
    }
    .padding()
}