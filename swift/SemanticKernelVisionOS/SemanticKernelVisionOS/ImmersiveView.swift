//
// Immersive View for visionOS Semantic Kernel Demo
// Simple 3D spatial environment showcasing AI concepts
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            // Create simple immersive AI environment
            await setupSimpleScene(content: content)
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    print("🥽 Tapped entity in immersive space: \(value.entity.name)")
                }
        )
    }
    
    @MainActor
    private func setupSimpleScene(content: RealityViewContent) async {
        // Create simple floating spheres representing AI capabilities
        let plugins = [
            ("Math", UIColor.blue, SIMD3<Float>(-0.5, 0.2, -1.0)),
            ("Text", UIColor.green, SIMD3<Float>(0.5, 0.2, -1.0)),
            ("Time", UIColor.orange, SIMD3<Float>(0.0, 0.5, -1.2)),
            ("AI Core", UIColor.purple, SIMD3<Float>(0.0, -0.2, -0.8))
        ]
        
        for (name, color, position) in plugins {
            let sphere = ModelEntity(
                mesh: .generateSphere(radius: 0.1),
                materials: [SimpleMaterial(color: color, isMetallic: false)]
            )
            
            sphere.name = name
            sphere.position = position
            sphere.components.set(InputTargetComponent(allowedInputTypes: .indirect))
            
            content.add(sphere)
        }
        
        // Add central AI brain visualization if available
        if let brainEntity = try? await Entity(named: "Scene", in: realityKitContentBundle) {
            brainEntity.position = SIMD3<Float>(0, 0, -1.5)
            brainEntity.scale = SIMD3<Float>(0.3, 0.3, 0.3)
            content.add(brainEntity)
        }
    }
}

#Preview {
    ImmersiveView()
}