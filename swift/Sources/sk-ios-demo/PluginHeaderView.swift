//
// Plugin Header View for iOS Semantic Kernel Demo
// Shows available plugins and suggested prompts
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PluginHeaderView: View {
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with plugin info
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "gear.badge.checkmark")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    Text("Semantic Kernel initialized with Math, Text, and Time plugins")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Suggestion buttons
            VStack(spacing: 12) {
                Text("Try these examples:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Math plugin suggestions
                HStack(spacing: 8) {
                    PluginSuggestionButton(
                        icon: "function",
                        text: "Calculate circle area (32cm)",
                        color: .blue,
                        action: { onSuggestionTap("Calculate the area of a circle with diameter 32 cm using π × (d/2)²") }
                    )
                    
                    PluginSuggestionButton(
                        icon: "plus.forwardslash.minus",
                        text: "Add 127 + 89",
                        color: .blue,
                        action: { onSuggestionTap("Use the math.add function to calculate 127 + 89") }
                    )
                }
                
                // Text plugin suggestions
                HStack(spacing: 8) {
                    PluginSuggestionButton(
                        icon: "textformat.abc.dottedunderline",
                        text: "Uppercase text",
                        color: .orange,
                        action: { onSuggestionTap("Use the text.upper function to convert 'hello world' to uppercase") }
                    )
                    
                    PluginSuggestionButton(
                        icon: "text.word.spacing",
                        text: "Count words",
                        color: .orange,
                        action: { onSuggestionTap("Use the text.length function to count characters in 'The quick brown fox jumps over the lazy dog'") }
                    )
                }
                
                // Time plugin suggestions
                HStack(spacing: 8) {
                    PluginSuggestionButton(
                        icon: "clock",
                        text: "Current time",
                        color: .green,
                        action: { onSuggestionTap("Call the time.now function to get the current time") }
                    )
                    
                    PluginSuggestionButton(
                        icon: "calendar",
                        text: "Today's date",
                        color: .green,
                        action: { onSuggestionTap("Call the time.today function to get today's date") }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct PluginSuggestionButton: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(text)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PluginHeaderView { suggestion in
        print("Tapped: \(suggestion)")
    }
}