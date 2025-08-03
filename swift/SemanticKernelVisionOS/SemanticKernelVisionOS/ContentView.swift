//
//  ContentView.swift
//  SemanticKernelVisionOS
//
//  Created by Amund Tveit on 23/07/2025.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some View {
        NavigationSplitView {
            VStack {
                // Spatial computing header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                        .font(.title)
                    
                    VStack(alignment: .leading) {
                        Text("Semantic Kernel")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("visionOS Spatial AI Demo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            if immersiveSpaceIsShown {
                                await dismissImmersiveSpace()
                                immersiveSpaceIsShown = false
                            } else {
                                await openImmersiveSpace(id: "ImmersiveSpace")
                                immersiveSpaceIsShown = true
                            }
                        }
                    }) {
                        Image(systemName: immersiveSpaceIsShown ? "xmark.circle" : "vision.pro")
                            .font(.title2)
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                Divider()
                
                // Plugin controls in spatial layout
                VisionOSPluginHeaderView { suggestion in
                    viewModel.sendMessage(suggestion)
                }
                
                Divider()
            }
        } detail: {
            // Main chat interface
            VStack(spacing: 0) {
                // Chat messages with depth
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                VisionOSMessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                VisionOSTypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message input
                VisionOSMessageInputView { message in
                    viewModel.sendMessage(message)
                }
            }
        }
        .navigationTitle("SK visionOS Demo")
        .onAppear {
            viewModel.initializeKernel()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
