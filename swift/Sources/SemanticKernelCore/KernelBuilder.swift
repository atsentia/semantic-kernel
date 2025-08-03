import Foundation
import SemanticKernelAbstractions
import Logging

/// Fluent builder for creating a `Kernel`.
public struct KernelBuilder: Sendable {
    private var serviceCollection = ServiceCollection()
    private struct FunctionRegistration {
        let name: String
        let metadata: KernelFunctionMetadata?
        let handler: @Sendable (KernelArguments) async throws -> KernelResult
    }
    private var functionRegistrations: [FunctionRegistration] = []
    private var pluginRegistrations: [(KernelPlugin, String?)] = []
    private var skPlugins: [SKPlugin] = []
    private var logger: Logger?
    private var metrics: MetricsSink = NoOpMetricsSink()

    public init() {}

    /// Add a service instance accessible by type.
    public mutating func withService<T: Sendable>(_ service: T) async -> Self {
        await serviceCollection.add(service)
        return self
    }

    /// Provide a logger used by the built Kernel.
    public mutating func withLogger(_ logger: Logger) -> Self {
        self.logger = logger
        return self
    }

    /// Provide a metrics sink used by the built Kernel.
    public mutating func withMetricsSink(_ sink: MetricsSink) -> Self {
        self.metrics = sink
        return self
    }

    /// Register a native function with the kernel.
    public mutating func withFunction(_ name: String, metadata: KernelFunctionMetadata? = nil, handler: @escaping @Sendable (KernelArguments) async throws -> KernelResult) -> Self {
        functionRegistrations.append(FunctionRegistration(name: name, metadata: metadata, handler: handler))
        return self
    }

    /// Register a plugin providing multiple functions.
    public mutating func withPlugin<P: KernelPlugin & Sendable>(_ plugin: P, namespace: String? = nil) -> Self {
        pluginRegistrations.append((plugin, namespace))
        return self
    }

    public mutating func withPlugin(_ plugin: SKPlugin & Sendable) -> Self {
        skPlugins.append(plugin)
        return self
    }

    /// Build the kernel with the configured services and functions.
    public func build() async -> Kernel {
        let logger = self.logger ?? Logger(label: "SemanticKernel", factory: { _ in SwiftLogNoOpLogHandler() })
        let memory: MemoryStore? = await serviceCollection.resolve()
        let kernel = Kernel(services: serviceCollection, logger: logger, metrics: metrics, memory: memory)
        for reg in functionRegistrations {
            await kernel.registerFunction(reg.name, metadata: reg.metadata, handler: reg.handler)
        }
        for (plugin, ns) in pluginRegistrations {
            await kernel.registerPlugin(plugin, namespace: ns)
        }
        for plugin in skPlugins {
            await plugin.register(with: kernel)
        }
        return kernel
    }
}
