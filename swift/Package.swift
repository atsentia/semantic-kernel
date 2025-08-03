// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SwiftSemanticKernel",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15),
        .visionOS(.v1),
    ],
    products: [
        // MARK: - Core Semantic Kernel Libraries
        // Main library that users should import
        .library(name: "SemanticKernel", targets: [
            "SemanticKernelAbstractions",
            "SemanticKernelCore", 
            "SemanticKernelSupport"
        ]),
        
        // Individual components for advanced users
        .library(name: "SemanticKernelAbstractions", targets: ["SemanticKernelAbstractions"]),
        .library(name: "SemanticKernelCore", targets: ["SemanticKernelCore"]),
        .library(name: "SemanticKernelSupport", targets: ["SemanticKernelSupport"]),
        
        // MARK: - Service Connectors
        .library(name: "SemanticKernelOpenAI", targets: ["SemanticKernelConnectorsOpenAI"]),
        .library(name: "SemanticKernelAzureOpenAI", targets: ["SemanticKernelConnectorsAzureOpenAI"]),
        .library(name: "SemanticKernelQdrant", targets: ["SemanticKernelConnectorsQdrant"]),
        
        // MARK: - Plugins
        .library(name: "SemanticKernelPlugins", targets: ["SemanticKernelPluginsCore"]),
        
        // MARK: - Model Context Protocol (MCP) Support
        .library(name: "SemanticKernelMCP", targets: ["MCPShared"]),
        
        // MARK: - Example Applications & Tools
        // Chat & Interactive Applications
        .executable(name: "sk-samples-cli", targets: ["sk-samples-cli"]),
        .executable(name: "sk-ios-demo", targets: ["sk-ios-demo"]),
        .executable(name: "mcp-filesystem-demo", targets: ["mcp-filesystem-demo"]),
        
        // Development & Testing Tools  
        .executable(name: "sk-bench", targets: ["sk-bench"]),
        .executable(name: "openai-api-call", targets: ["openai-api-call"]),
        .executable(name: "architecture-test", targets: ["architecture-test"]),
        .executable(name: "api-test", targets: ["api-test"]),
        .executable(name: "plugin-test", targets: ["plugin-test"]),
        .executable(name: "chatagent-test", targets: ["chatagent-test"]),
        .executable(name: "function-calling-test", targets: ["function-calling-test"]),
        .executable(name: "model-comparison-test", targets: ["model-comparison-test"]),
        .executable(name: "function-calling-debug", targets: ["function-calling-debug"]),
        .executable(name: "json-debug", targets: ["json-debug"]),
        .executable(name: "debug-planner-test", targets: ["debug-planner-test"]),
        .executable(name: "debug-messages-test", targets: ["debug-messages-test"]),
        .executable(name: "simple-function-test", targets: ["simple-function-test"]),
        .executable(name: "connectivity-test", targets: ["connectivity-test"]),
        .executable(name: "curl-test", targets: ["curl-test"]),
        .executable(name: "function-curl-test", targets: ["function-curl-test"]),
        .executable(name: "test-responses-api", targets: ["test-responses-api"]),
        
        // MCP Server Examples
        .executable(name: "hello-mcp-server", targets: ["hello-mcp-server"]),
        .executable(name: "filesystem-mcp-server-basic", targets: ["filesystem-mcp-server-basic"]),
        .executable(name: "filesystem-mcp-server-jwt", targets: ["filesystem-mcp-server-jwt"]),
        .executable(name: "filesystem-mcp-server-oauth", targets: ["filesystem-mcp-server-oauth"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    ],
    targets: [
        // MARK: - Core Semantic Kernel Library Targets
        .target(
            name: "SemanticKernelAbstractions",
            dependencies: []
        ),
        .target(
            name: "SemanticKernelCore", 
            dependencies: [
                "SemanticKernelAbstractions",
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "SemanticKernelSupport", 
            dependencies: []
        ),
        
        // MARK: - Service Connector Targets
        .target(
            name: "SemanticKernelConnectorsOpenAI", 
            dependencies: [
                "SemanticKernelCore",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .target(
            name: "SemanticKernelConnectorsAzureOpenAI", 
            dependencies: [
                "SemanticKernelCore",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .target(
            name: "SemanticKernelConnectorsQdrant", 
            dependencies: [
                "SemanticKernelCore",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        
        // MARK: - Plugin Targets
        .target(
            name: "SemanticKernelPluginsCore", 
            dependencies: [
                "SemanticKernelCore",
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        
        // MARK: - MCP Support Targets
        .target(
            name: "MCPShared", 
            dependencies: []
        ),
        
        // MARK: - Example Application Targets
        // Chat & Interactive Applications
        .executableTarget(
            name: "sk-samples-cli", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore"
            ]
        ),
        .executableTarget(
            name: "sk-ios-demo", 
            dependencies: [
                "SemanticKernelCore",
                "SemanticKernelConnectorsOpenAI",
                "SemanticKernelPluginsCore"
            ], 
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "mcp-filesystem-demo", 
            dependencies: [
                "MCPShared",
                "SemanticKernelCore",
                "SemanticKernelConnectorsOpenAI"
            ], 
            exclude: ["README.md"]
        ),
        
        // Development & Testing Tools
        .executableTarget(
            name: "sk-bench", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore"
            ]
        ),
        .executableTarget(
            name: "openai-api-call", 
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ], 
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "api-test", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore",
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "plugin-test", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore",
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "chatagent-test", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore",
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "function-calling-test", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore",
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "model-comparison-test", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore",
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "function-calling-debug", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore",
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "json-debug", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore",
                "SemanticKernelConnectorsOpenAI"
            ]
        ),
        .executableTarget(
            name: "debug-planner-test", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore",
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "debug-messages-test", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore",
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "simple-function-test", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore",
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "connectivity-test", 
            dependencies: [
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "curl-test", 
            dependencies: [
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "function-curl-test", 
            dependencies: [
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "test-responses-api", 
            dependencies: [
                "SemanticKernelConnectorsOpenAI",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .executableTarget(
            name: "openai-responses-cli", 
            dependencies: ["SemanticKernelConnectorsOpenAI"]
        ),
        .executableTarget(
            name: "architecture-test",
            dependencies: [
                "SemanticKernelCore",
                "SemanticKernelConnectorsOpenAI", 
                "SemanticKernelPluginsCore",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        
        // MCP Server Examples
        .executableTarget(
            name: "hello-mcp-server", 
            dependencies: [], 
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "filesystem-mcp-server-basic", 
            dependencies: [], 
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "filesystem-mcp-server-jwt", 
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ], 
            exclude: ["README.md"], 
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        .executableTarget(
            name: "filesystem-mcp-server-oauth", 
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ], 
            exclude: ["README.md"], 
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        
        // MARK: - Test Targets
        .testTarget(
            name: "SemanticKernelAbstractionsTests", 
            dependencies: ["SemanticKernelAbstractions"]
        ),
        .testTarget(
            name: "sk-ios-demo-UITests",
            dependencies: [],
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "SemanticKernelCoreTests", 
            dependencies: [
                "SemanticKernelCore", 
                "SemanticKernelPluginsCore"
            ]
        ),
        .testTarget(
            name: "SemanticKernelConnectorsOpenAITests", 
            dependencies: ["SemanticKernelConnectorsOpenAI"]
        ),
        .testTarget(
            name: "SemanticKernelConnectorsAzureOpenAITests", 
            dependencies: ["SemanticKernelConnectorsAzureOpenAI"]
        ),
        .testTarget(
            name: "SemanticKernelConnectorsQdrantTests", 
            dependencies: ["SemanticKernelConnectorsQdrant"]
        ),
        .testTarget(
            name: "SemanticKernelPluginsCoreTests", 
            dependencies: [
                "SemanticKernelPluginsCore",
                "SemanticKernelCore",
                "SemanticKernelConnectorsOpenAI"
            ]
        ),
    ]
)
