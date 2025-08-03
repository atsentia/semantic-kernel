//
//  SemanticKernelVisionOSApp.swift
//  SemanticKernelVisionOS
//
//  Created by Amund Tveit on 23/07/2025.
//

import SwiftUI

@main
struct SemanticKernelVisionOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
