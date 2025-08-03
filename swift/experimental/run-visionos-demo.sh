#!/bin/bash
#
# Run visionOS Semantic Kernel Demo in Vision Pro Simulator
# Automatically builds and launches the visionOS app
#

set -e

# Color output functions
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

echo ""
blue "🥽 Swift Semantic Kernel - visionOS Demo Launcher"
echo "=================================================="

# Check if we're in the correct directory
if [ ! -f "Package.swift" ]; then
    red "❌ Error: Package.swift not found. Please run this script from the project root."
    exit 1
fi

# Check if .env file exists and load it
if [ -f ".env" ]; then
    green "✅ Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
else
    yellow "⚠️  No .env file found. Make sure OPENAI_API_KEY is set in your environment."
fi

# Check for OPENAI_API_KEY
if [ -z "$OPENAI_API_KEY" ]; then
    red "❌ Error: OPENAI_API_KEY not found in environment or .env file"
    echo "   Please create a .env file with:"
    echo "   OPENAI_API_KEY=\"your_openai_api_key_here\""
    exit 1
fi

green "✅ OpenAI API key configured"

# Check for xcrun and xcodebuild
if ! command -v xcrun &> /dev/null; then
    red "❌ Error: xcrun not found. Please install Xcode Command Line Tools."
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    red "❌ Error: xcodebuild not found. Please install Xcode."
    exit 1
fi

# List available visionOS simulators
echo ""
blue "🔍 Checking for visionOS simulators..."

# Get Vision Pro simulator (available or not)
SIMULATOR_UDID=$(xcrun simctl list devices | grep -A1 "visionOS" | grep "Apple Vision Pro" | sed 's/.*(\([^)]*\)).*/\1/' | head -1)

if [ -z "$SIMULATOR_UDID" ]; then
    red "❌ Error: No Vision Pro simulator found."
    echo "   Please install Vision Pro simulator from Xcode > Platforms > visionOS"
    exit 1
fi


SIMULATOR_NAME="Apple Vision Pro"

green "✅ Using simulator: $SIMULATOR_NAME"

# Start the simulator if not running
echo ""
blue "🚀 Starting Vision Pro simulator..."
xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
sleep 3

# Open Simulator app
open -a Simulator --args -CurrentDeviceUDID "$SIMULATOR_UDID"
sleep 5

# Build the visionOS app
echo ""
blue "🔨 Building visionOS Semantic Kernel Demo..."

# Clean build directory
rm -rf .build

# Build for visionOS simulator
swift build --product sk-visionos-demo -c release --arch arm64 --sdk xrsimulator

if [ $? -ne 0 ]; then
    red "❌ Build failed. Please check the error messages above."
    exit 1
fi

green "✅ Build completed successfully"

# Find the built executable
BUILT_EXECUTABLE=$(find .build -name "sk-visionos-demo" -type f -perm +111 | head -1)

if [ -z "$BUILT_EXECUTABLE" ]; then
    red "❌ Error: Built executable not found"
    exit 1
fi

echo ""
blue "🎯 Deploying to Vision Pro simulator..."

# Create app bundle structure
APP_BUNDLE_PATH="/tmp/sk-visionos-demo.app"
rm -rf "$APP_BUNDLE_PATH"
mkdir -p "$APP_BUNDLE_PATH"

# Copy executable
cp "$BUILT_EXECUTABLE" "$APP_BUNDLE_PATH/sk-visionos-demo"

# Create Info.plist for visionOS
cat > "$APP_BUNDLE_PATH/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>sk-visionos-demo</string>
    <key>CFBundleIdentifier</key>
    <string>com.semantickernel.swift.visionos-demo</string>
    <key>CFBundleName</key>
    <string>SK visionOS Demo</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>1.0</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>7</integer>
    </array>
    <key>UILaunchScreen</key>
    <dict>
        <key>UIImageName</key>
        <string>LaunchImage</string>
    </dict>
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

# Install the app
xcrun simctl install "$SIMULATOR_UDID" "$APP_BUNDLE_PATH"

if [ $? -ne 0 ]; then
    red "❌ Installation failed"
    exit 1
fi

green "✅ App installed successfully"

# Launch the app
echo ""
blue "🎊 Launching visionOS Semantic Kernel Demo..."
xcrun simctl launch "$SIMULATOR_UDID" "com.semantickernel.swift.visionos-demo"

if [ $? -eq 0 ]; then
    echo ""
    green "🥽 SUCCESS! visionOS Semantic Kernel Demo is now running in Vision Pro simulator"
    echo ""
    echo "Features available in the visionOS demo:"
    echo "• 🧮 Math Plugin - Advanced calculations in spatial computing"
    echo "• 📝 Text Plugin - Text manipulation with 3D visualization"
    echo "• ⏰ Time Plugin - Time operations in immersive environment"
    echo "• 🌟 Volumetric Windows - Spatial UI elements"
    echo "• 🎭 Immersive Mode - Full 3D spatial experience"
    echo ""
    echo "Try these sample prompts:"
    echo "• 'Calculate the square root of 144'"
    echo "• 'Convert this text to uppercase: hello world'"
    echo "• 'What time is it now?'"
    echo "• 'Toggle immersive mode for 3D experience'"
    echo ""
    blue "Enjoy exploring Semantic Kernel in spatial computing! 🚀"
else
    red "❌ Launch failed. Check the simulator for error details."
    exit 1
fi