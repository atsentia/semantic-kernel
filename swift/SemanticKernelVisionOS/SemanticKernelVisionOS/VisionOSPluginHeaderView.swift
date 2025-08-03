//
// Plugin Header View for visionOS
// Displays available Semantic Kernel plugins in spatial 3D layout
//

import SwiftUI

struct VisionOSPluginHeaderView: View {
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "puzzlepiece.extension.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("AI Function Plugins")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Tap to try")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Plugin cards in spatial grid layout (matching iOS examples)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                PluginCard(
                    title: "Math",
                    icon: "function",
                    color: .blue,
                    suggestions: [
                        "Calculate the area of a circle with diameter 32 cm using π × (d/2)²",
                        "Use the math.add function to calculate 127 + 89",
                        "What is 15 × 23?"
                    ]
                ) { suggestion in
                    onSuggestionTap(suggestion)
                }
                
                PluginCard(
                    title: "Text",
                    icon: "textformat",
                    color: .orange,
                    suggestions: [
                        "Use the text.upper function to convert 'hello world' to uppercase",
                        "Use the text.length function to count characters in 'The quick brown fox jumps over the lazy dog'",
                        "Reverse this text: visionOS"
                    ]
                ) { suggestion in
                    onSuggestionTap(suggestion)
                }
                
                PluginCard(
                    title: "Time",
                    icon: "clock.fill",
                    color: .green,
                    suggestions: [
                        "Call the time.now function to get the current time",
                        "Call the time.today function to get today's date",
                        "What day of the week is it?"
                    ]
                ) { suggestion in
                    onSuggestionTap(suggestion)
                }
                
                PluginCard(
                    title: "Reality",
                    icon: "vision.pro",
                    color: .purple,
                    suggestions: [
                        "Show me a 3D cube",
                        "Create spatial visualization",
                        "Toggle immersive mode"
                    ]
                ) { suggestion in
                    onSuggestionTap(suggestion)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PluginCard: View {
    let title: String
    let icon: String
    let color: Color
    let suggestions: [String]
    let onSuggestionTap: (String) -> Void
    
    @State private var selectedSuggestion = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            Button(action: {
                onSuggestionTap(suggestions[selectedSuggestion])
                selectedSuggestion = (selectedSuggestion + 1) % suggestions.count
            }) {
                Text(suggestions[selectedSuggestion])
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .hoverEffect(.highlight)
    }
}

#Preview {
    VisionOSPluginHeaderView { suggestion in
        print("Suggestion tapped: \(suggestion)")
    }
    .padding()
}