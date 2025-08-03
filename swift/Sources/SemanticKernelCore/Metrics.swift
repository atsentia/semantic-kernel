import Foundation

/// Events that can be recorded by a `MetricsSink`.
public enum MetricEvent {
    case tokensUsed(Int)
    case callDuration(name: String, seconds: Double)
}

/// Protocol for receiving metric events.
public protocol MetricsSink: Sendable {
    func record(_ event: MetricEvent)
}

/// Default no-op metrics sink used when none is provided.
public struct NoOpMetricsSink: MetricsSink {
    public init() {}
    public func record(_ event: MetricEvent) {}
}
