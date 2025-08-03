#!/bin/bash
#
# Create standalone visionOS Xcode project
# This bypasses Swift Package Manager cross-compilation issues
#

set -e

# Color output functions
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

echo ""
blue "🥽 Creating Standalone visionOS Xcode Project"
echo "============================================="

PROJECT_DIR="VisionOSSemanticKernel"
XCODE_PROJECT="${PROJECT_DIR}/${PROJECT_DIR}.xcodeproj"

# Clean up existing project
if [ -d "$PROJECT_DIR" ]; then
    rm -rf "$PROJECT_DIR"
fi

# Create project structure
mkdir -p "${PROJECT_DIR}/${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}/${PROJECT_DIR}/SemanticKernel"

blue "📁 Creating project structure..."

# Copy visionOS source files
cp -r Sources/sk-visionos-demo/* "${PROJECT_DIR}/${PROJECT_DIR}/"

# Copy SemanticKernel source files (flattened)
cp -r Sources/SemanticKernelAbstractions/* "${PROJECT_DIR}/${PROJECT_DIR}/SemanticKernel/"
cp -r Sources/SemanticKernelCore/* "${PROJECT_DIR}/${PROJECT_DIR}/SemanticKernel/"
cp -r Sources/SemanticKernelSupport/* "${PROJECT_DIR}/${PROJECT_DIR}/SemanticKernel/"
cp -r Sources/SemanticKernelConnectorsOpenAI/* "${PROJECT_DIR}/${PROJECT_DIR}/SemanticKernel/"
cp -r Sources/SemanticKernelPluginsCore/* "${PROJECT_DIR}/${PROJECT_DIR}/SemanticKernel/"

green "✅ Source files copied"

# Create minimal Info.plist
cat > "${PROJECT_DIR}/${PROJECT_DIR}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(XROS_DEPLOYMENT_TARGET)</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>7</integer>
    </array>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOF

blue "🛠️  Creating Xcode project..."

# Use xcodebuild to create the project
cd "$PROJECT_DIR"

# Create a simple Package.swift for local development
cat > Package.swift << 'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VisionOSSemanticKernel",
    platforms: [.visionOS(.v1)],
    products: [
        .executable(name: "VisionOSSemanticKernel", targets: ["VisionOSSemanticKernel"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "VisionOSSemanticKernel",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Logging", package: "swift-log")
            ],
            path: "VisionOSSemanticKernel"
        )
    ]
)
EOF

# Generate Xcode project
swift package generate-xcodeproj --skip-extra-files

if [ $? -eq 0 ]; then
    green "✅ Xcode project created successfully!"
    echo ""
    echo "📂 Project location: $(pwd)/${PROJECT_DIR}.xcodeproj"
    echo ""
    blue "🚀 Opening in Xcode..."
    open "${PROJECT_DIR}.xcodeproj"
    echo ""
    green "Next steps in Xcode:"
    echo "1. Select 'VisionOSSemanticKernel' scheme"
    echo "2. Choose 'Apple Vision Pro' simulator as destination"
    echo "3. Click Run (⌘+R)"
    echo ""
    echo "🥽 Enjoy your visionOS Semantic Kernel demo!"
else
    red "❌ Failed to create Xcode project"
    exit 1
fi