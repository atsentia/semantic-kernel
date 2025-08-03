//
// Typing Indicator Component for iOS Chat Interface
// Shows animated dots when waiting for AI response
//

import SwiftUI

struct TypingIndicator: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animationAmount)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: animationAmount
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Text("AI is typing...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            }
            
            Spacer(minLength: 50)
        }
        .onAppear {
            animationAmount = 1.2
        }
        .onDisappear {
            animationAmount = 0.0
        }
    }
}

#Preview {
    TypingIndicator()
        .padding()
}