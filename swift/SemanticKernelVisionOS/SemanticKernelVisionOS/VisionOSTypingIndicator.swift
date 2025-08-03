//
// Typing Indicator for visionOS
// Spatial loading animation for AI processing
//

import SwiftUI

struct VisionOSTypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    @State private var opacity: Double = 0.3
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "brain.head.profile.fill")
                    .foregroundColor(.purple)
                    .font(.caption)
                
                Text("Spatial AI is thinking")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.purple.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .scaleEffect(1.0 + sin(animationOffset + Double(index) * 0.4) * 0.3)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
        .opacity(opacity)
        .onAppear {
            animationOffset = .pi * 2
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 1.0
            }
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
    }
}

#Preview {
    VStack(spacing: 20) {
        VisionOSTypingIndicator()
        
        Text("Spatial AI Processing...")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}