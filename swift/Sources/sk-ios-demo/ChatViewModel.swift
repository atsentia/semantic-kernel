//
// Chat View Model for iOS Semantic Kernel Demo
// Handles chat state and Semantic Kernel integration
//

import SwiftUI
import SemanticKernelCore
import SemanticKernelConnectorsOpenAI
import SemanticKernelPluginsCore
import SemanticKernelAbstractions

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isWaitingForResponse: Bool = false
    @Published var kernelStatus: KernelStatus = .notInitialized
    
    private var kernel: Kernel?
    private var chatAgent: ChatAgent?
    
    enum KernelStatus: Equatable {
        case notInitialized
        case initializing
        case ready
        case error(String)
        
        var description: String {
            switch self {
            case .notInitialized: return "Not initialized"
            case .initializing: return "Initializing..."
            case .ready: return "Ready"
            case .error(let message): return "Error: \(message)"
            }
        }
    }
    
    init() {
        // Start with empty messages - header shows functionality
    }
    
    func initializeKernel() {
        guard kernelStatus == .notInitialized else { return }
        
        kernelStatus = .initializing
        
        Task {
            do {
                // Check for API key (supports both environment variable and .env file)
                guard let apiKey = SemanticKernelConnectorsOpenAI.Environment.apiKey else {
                    await MainActor.run {
                        self.kernelStatus = .error("OpenAI API key not found. Please set OPENAI_API_KEY environment variable or add it to .env file.")
                        self.addSystemMessage("⚠️ OpenAI API key not configured. Please add OPENAI_API_KEY to your .env file in the project root.")
                    }
                    return
                }
                
                var builder = KernelBuilder()
                
                // Add OpenAI chat completion service
                let chatService = OpenAIChatCompletionService(
                    apiKey: apiKey,
                    model: "gpt-4"
                )
                builder = await builder.withService(chatService as ChatCompletionService)
                
                // Add core plugins
                builder = builder.withPlugin(MathPlugin())
                builder = builder.withPlugin(TextPlugin())
                builder = builder.withPlugin(TimePlugin())
                
                let builtKernel = await builder.build()
                
                // Create planner and chat agent
                let planner = FunctionCallingStepwisePlanner(kernel: builtKernel)
                let agent = ChatAgent(planner: planner)
                
                await MainActor.run {
                    self.kernel = builtKernel 
                    self.chatAgent = agent
                    self.kernelStatus = .ready
                    self.addSystemMessage("✅ Semantic Kernel initialized with Math, Text, and Time plugins.")
                }
                
            } catch {
                await MainActor.run {
                    self.kernelStatus = .error(error.localizedDescription)
                    self.addSystemMessage("❌ Failed to initialize Semantic Kernel: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func sendMessage() {
        let messageText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: messageText, isFromUser: true)
        messages.append(userMessage)
        
        // Clear input
        inputText = ""
        isWaitingForResponse = true
        
        Task {
            do {
                let response = try await getAIResponse(for: messageText)
                await MainActor.run {
                    let aiMessage = ChatMessage(content: response, isFromUser: false)
                    self.messages.append(aiMessage)
                    self.isWaitingForResponse = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        content: "Sorry, I encountered an error: \(error.localizedDescription)",
                        isFromUser: false
                    )
                    self.messages.append(errorMessage)
                    self.isWaitingForResponse = false
                }
            }
        }
    }
    
    func clearChat() {
        messages.removeAll()
    }
    
    private func addSystemMessage(_ content: String) {
        let systemMessage = ChatMessage(content: content, isFromUser: false)
        messages.append(systemMessage)
    }
    
    private func getAIResponse(for message: String) async throws -> String {
        guard let chatAgent = chatAgent else {
            return "Semantic Kernel is not initialized. Please check your configuration."
        }
        
        do {
            print("Sending message to ChatAgent with plugin support...")
            let response = try await chatAgent.send(message)
            return response
            
        } catch {
            print("Error getting AI response: \(error)")
            return "Error connecting to AI service: \(error.localizedDescription). Using fallback response: \(generateFallbackResponse(for: message))"
        }
    }
    
    private func generateFallbackResponse(for message: String) -> String {
        let lowercased = message.lowercased()
        
        if lowercased.contains("math") || lowercased.contains("calculate") || lowercased.contains("number") {
            return "I can help with mathematical calculations using the Math plugin. Try asking me to calculate something specific!"
        } else if lowercased.contains("time") || lowercased.contains("date") {
            return "I can help with time and date operations using the Time plugin. Ask me about the current time or date calculations!"
        } else if lowercased.contains("text") || lowercased.contains("string") {
            return "I can help with text manipulation using the Text plugin. Try asking me to transform or analyze some text!"
        } else {
            return "I'm here to help! I have access to Math, Text, and Time plugins through Semantic Kernel. What would you like to do?"
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp = Date()
}

