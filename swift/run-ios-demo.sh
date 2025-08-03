#!/bin/bash

# Script to run sk-ios-demo in iOS Simulator without Xcode
set -e

echo "🚀 Building and running sk-ios-demo in iOS Simulator..."

# Find an available iOS simulator device
echo "🔍 Finding available iOS simulators..."
DEVICE_INFO=$(xcrun simctl list devices available | grep "iPhone" | head -1)

if [ -z "$DEVICE_INFO" ]; then
    echo "❌ No iOS simulators found. Please install Xcode and iOS Simulator."
    exit 1
fi

# Extract device ID from the device info line
DEVICE_ID=$(echo "$DEVICE_INFO" | grep -o '([A-F0-9-]\{36\})' | tr -d '()')
DEVICE_NAME=$(echo "$DEVICE_INFO" | sed 's/ (.*$//')

echo "📱 Using device: $DEVICE_NAME"
echo "🆔 Device ID: $DEVICE_ID"

# Boot the simulator if not already running
echo "📱 Starting iOS Simulator..."
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || echo "Simulator already running"

# Open Simulator application
open -a Simulator

echo "⏳ Waiting for simulator to fully boot..."
sleep 8

echo "🔨 Building for iOS Simulator using xcodebuild..."

# Try building directly with xcodebuild for iOS simulator
# This uses the Package.swift as the project definition
xcodebuild -scheme sk-ios-demo \
    -destination "platform=iOS Simulator,id=$DEVICE_ID" \
    -configuration Debug \
    -derivedDataPath .build/xcode \
    build

echo "🎯 Installing and launching sk-ios-demo..."

# Find the built executable
EXECUTABLE_PATH=$(find .build/xcode -name "sk-ios-demo" -path "*/Products/Debug-iphonesimulator/*" | head -1)

if [ -z "$EXECUTABLE_PATH" ]; then
    echo "❌ Could not find built iOS executable."
    echo "🔄 Falling back to macOS build..."
    
    # Build as macOS app
    swift build --product sk-ios-demo
    
    echo "✅ Built as macOS app (iOS-like interface)"
    echo "🚀 Starting app..."
    
    ./.build/debug/sk-ios-demo
    
else
    echo "📦 Found iOS executable at: $EXECUTABLE_PATH"
    
    # Create a temporary app bundle for the iOS simulator
    TEMP_APP_DIR=".build/sk-ios-demo.app"
    rm -rf "$TEMP_APP_DIR"
    mkdir -p "$TEMP_APP_DIR"
    
    # Copy the executable
    cp "$EXECUTABLE_PATH" "$TEMP_APP_DIR/sk-ios-demo"
    chmod +x "$TEMP_APP_DIR/sk-ios-demo"
    
    # Create a minimal Info.plist
    cat > "$TEMP_APP_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.semantickernel.sk-ios-demo</string>
    <key>CFBundleName</key>
    <string>sk-ios-demo</string>
    <key>CFBundleDisplayName</key>
    <string>Semantic Kernel iOS Demo</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>sk-ios-demo</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOF
    
    # Install the app bundle to simulator
    xcrun simctl install "$DEVICE_ID" "$TEMP_APP_DIR"
    
    # Launch the app
    BUNDLE_ID="com.semantickernel.sk-ios-demo"
    xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"
    
    echo "✅ sk-ios-demo is now running in iOS Simulator!"
    echo "📱 Device: $DEVICE_NAME" 
    echo "🔗 Bundle ID: $BUNDLE_ID"
    echo "📦 App bundle created at: $TEMP_APP_DIR"
fi