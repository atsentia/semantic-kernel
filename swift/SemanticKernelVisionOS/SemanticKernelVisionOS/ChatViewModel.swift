//
// Chat View Model for visionOS Semantic Kernel Demo
// Enhanced for spatial computing with immersive features
//

import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var kernelStatus: KernelStatus = .notInitialized
    @Published var immersiveMode: Bool = false
    
    private var kernel: Any? // Kernel placeholder
    private var chatAgent: Any? // ChatAgent placeholder
    
    enum KernelStatus: Equatable {
        case notInitialized
        case initializing
        case ready
        case error(String)
        
        var description: String {
            switch self {
            case .notInitialized: return "Spatial AI Not Initialized"
            case .initializing: return "Connecting to AI Reality..."
            case .ready: return "Spatial AI Ready"
            case .error(let message): return "Spatial AI Error: \(message)"
            }
        }
        
        var systemName: String {
            switch self {
            case .notInitialized: return "brain.head.profile"
            case .initializing: return "brain.head.profile.fill"
            case .ready: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .notInitialized: return .gray
            case .initializing: return .blue
            case .ready: return .green
            case .error: return .red
            }
        }
    }
    
    init() {
        // Initialize with welcome message for visionOS
        addSystemMessage("🥽 Welcome to Semantic Kernel for visionOS! This is a demo interface for spatial AI interactions.")
        addSystemMessage("🚀 Spatial AI Demo Ready! (Note: Full Semantic Kernel integration requires Swift Package Manager setup)")
    }
    
    func initializeKernel() {
        guard kernelStatus == .notInitialized else { return }
        
        kernelStatus = .initializing
        
        Task {
            // Simulate initialization
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                self.kernelStatus = .ready
                self.addSystemMessage("🚀 Spatial AI Demo Ready! (Note: Full Semantic Kernel integration requires Swift Package Manager setup)")
            }
        }
    }
    
    func sendMessage(_ messageText: String) {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message with spatial context
        let userMessage = ChatMessage(
            content: messageText,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        isLoading = true
        
        Task {
            // Simulate AI response for demo
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            await MainActor.run {
                let response = self.generateDemoResponse(for: messageText)
                let aiMessage = ChatMessage(
                    content: response,
                    isUser: false,
                    timestamp: Date()
                )
                self.messages.append(aiMessage)
                self.isLoading = false
            }
        }
    }
    
    func toggleImmersiveMode() {
        withAnimation(.easeInOut(duration: 0.5)) {
            immersiveMode.toggle()
        }
    }
    
    func clearChat() {
        withAnimation(.easeOut(duration: 0.3)) {
            messages.removeAll()
        }
        addSystemMessage("🧹 Chat cleared. Ready for new spatial AI interactions!")
    }
    
    private func addSystemMessage(_ content: String) {
        let systemMessage = ChatMessage(
            content: content,
            isUser: false,
            timestamp: Date()
        )
        messages.append(systemMessage)
    }
    
    private func generateDemoResponse(for message: String) -> String {
        let lowercased = message.lowercased()
        
        // Math plugin responses
        if lowercased.contains("circle") && lowercased.contains("diameter") && lowercased.contains("32") {
            return "🧮 **Math Plugin Result**: The area of a circle with diameter 32 cm is approximately **804.25 cm²** (using π × (32/2)² = π × 16² ≈ 804.25)"
        } else if lowercased.contains("127") && lowercased.contains("89") && lowercased.contains("add") {
            return "🧮 **Math Plugin Result**: math.add(127, 89) = **216**"
        } else if lowercased.contains("15") && lowercased.contains("23") {
            return "🧮 **Math Plugin Result**: 15 × 23 = **345**"
        } else if lowercased.contains("math") || lowercased.contains("calculate") || lowercased.contains("+") || lowercased.contains("×") {
            return "🧮 **Math Plugin**: I can perform calculations using functions like math.add, math.multiply, math.subtract, and more complex operations!"
            
        // Text plugin responses  
        } else if lowercased.contains("text.upper") && lowercased.contains("hello world") {
            return "📝 **Text Plugin Result**: text.upper('hello world') = **'HELLO WORLD'**"
        } else if lowercased.contains("text.length") && lowercased.contains("quick brown fox") {
            return "📝 **Text Plugin Result**: text.length('The quick brown fox jumps over the lazy dog') = **43 characters**"
        } else if lowercased.contains("reverse") && lowercased.contains("visionos") {
            return "📝 **Text Plugin Result**: Reversing 'visionOS' = **'SOnoisiV'**"
        } else if lowercased.contains("text") || lowercased.contains("string") || lowercased.contains("uppercase") {
            return "📝 **Text Plugin**: I can manipulate text using functions like text.upper, text.lower, text.length, and more!"
            
        // Time plugin responses
        } else if lowercased.contains("time.now") {
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            return "🕐 **Time Plugin Result**: time.now() = **\(formatter.string(from: Date()))**"
        } else if lowercased.contains("time.today") {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            return "📅 **Time Plugin Result**: time.today() = **\(formatter.string(from: Date()))**"
        } else if lowercased.contains("day of the week") {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "📅 **Time Plugin Result**: Today is **\(formatter.string(from: Date()))**"
        } else if lowercased.contains("time") || lowercased.contains("date") || lowercased.contains("now") {
            return "🕐 **Time Plugin**: I can provide time information using functions like time.now, time.today, and date calculations!"
            
        // Reality/visionOS specific
        } else if lowercased.contains("3d cube") {
            return "🥽 **Reality Plugin**: Creating a 3D cube visualization in spatial computing environment! (This would integrate with RealityKit)"
        } else if lowercased.contains("spatial") || lowercased.contains("immersive") {
            return "🥽 **Reality Plugin**: Spatial computing features would be enhanced with full Semantic Kernel integration!"
        } else {
            return "🤖 **visionOS Demo**: This demonstrates Semantic Kernel plugin integration. For full functionality, add Swift Package Manager dependencies: SemanticKernelCore, SemanticKernelConnectorsOpenAI, SemanticKernelPluginsCore!"
        }
    }
}

// Enhanced ChatMessage for visionOS
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool, timestamp: Date) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// Enhanced error handling for spatial computing
enum ChatError: LocalizedError {
    case kernelNotInitialized
    case kernelNotReady
    case aiResponseFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .kernelNotInitialized:
            return "Spatial AI kernel is not initialized. Please restart the app."
        case .kernelNotReady:
            return "Spatial AI is not ready. Please wait for initialization to complete."
        case .aiResponseFailed(let message):
            return "AI response failed in spatial context: \(message)"
        }
    }
}