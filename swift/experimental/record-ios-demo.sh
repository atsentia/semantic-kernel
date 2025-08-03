#!/bin/bash

# iOS Demo Video Recording Script
# This script builds the sk-ios-demo app, launches it in the iOS Simulator,
# and records a video demonstrating all 6 function calling features

set -e

echo "🎬 Starting iOS Demo Video Recording..."

# Configuration
APP_NAME="sk-ios-demo"
VIDEO_FILE="sk-ios-demo-function-calling-demo.mp4"
DEVICE_TYPE="iPhone 16 Pro"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Finding iOS Simulator device...${NC}"

# Get the device ID for iPhone 16 Pro (or first available)
DEVICE_ID=$(xcrun simctl list devices available | grep "$DEVICE_TYPE" | head -1 | grep -E -o -i "([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})")

if [ -z "$DEVICE_ID" ]; then
    echo -e "${YELLOW}⚠️  iPhone 16 Pro not found, using first available device...${NC}"
    DEVICE_ID=$(xcrun simctl list devices available | grep -E -o -i "([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})" | head -1)
fi

if [ -z "$DEVICE_ID" ]; then
    echo -e "${RED}❌ No iOS Simulator devices available${NC}"
    exit 1
fi

DEVICE_NAME=$(xcrun simctl list devices | grep "$DEVICE_ID" | sed 's/.*(\([^)]*\)).*/\1/' | tr -d '()')

echo -e "${GREEN}✅ Using device: $DEVICE_NAME${NC}"
echo -e "${GREEN}🆔 Device ID: $DEVICE_ID${NC}"

# Start the simulator if not running
echo -e "${BLUE}📱 Starting iOS Simulator...${NC}"
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true

# Wait for simulator to be ready
echo -e "${BLUE}⏳ Waiting for simulator to fully boot...${NC}"
xcrun simctl bootstatus "$DEVICE_ID" -b

# Build the app
echo -e "${BLUE}🔨 Building sk-ios-demo for iOS Simulator...${NC}"
swift build --product sk-ios-demo \
    -Xswiftc -sdk -Xswiftc "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
    -Xswiftc -target -Xswiftc "arm64-apple-ios15.0-simulator"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Create app bundle directory
APP_BUNDLE_PATH="/tmp/sk-ios-demo.app"
rm -rf "$APP_BUNDLE_PATH"
mkdir -p "$APP_BUNDLE_PATH"

# Copy binary
cp ".build/debug/sk-ios-demo" "$APP_BUNDLE_PATH/sk-ios-demo"

# Create Info.plist
cat > "$APP_BUNDLE_PATH/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>sk-ios-demo</string>
    <key>CFBundleIdentifier</key>
    <string>com.atsentia.sk-ios-demo</string>
    <key>CFBundleName</key>
    <string>SK iOS Demo</string>
    <key>CFBundleDisplayName</key>
    <string>Semantic Kernel iOS Demo</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
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
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
</dict>
</plist>
EOF

# Install the app
echo -e "${BLUE}📱 Installing app to simulator...${NC}"
xcrun simctl install "$DEVICE_ID" "$APP_BUNDLE_PATH"

# Clean up any previous recordings
rm -f "$VIDEO_FILE"

echo -e "${GREEN}🎬 Starting video recording...${NC}"
echo -e "${YELLOW}📹 Recording will be saved as: $VIDEO_FILE${NC}"

# Start recording in background
xcrun simctl io "$DEVICE_ID" recordVideo "$VIDEO_FILE" &
RECORDING_PID=$!

# Wait a moment for recording to start
sleep 2

# Launch the app
echo -e "${BLUE}🚀 Launching sk-ios-demo...${NC}"
xcrun simctl launch "$DEVICE_ID" com.atsentia.sk-ios-demo

echo -e "${GREEN}✅ App launched successfully!${NC}"
echo -e ""
echo -e "${YELLOW}🎭 DEMO INSTRUCTIONS:${NC}"
echo -e "${YELLOW}===================${NC}"
echo -e "The app is now running and being recorded."
echo -e "Please manually test the following 6 suggestion buttons:"
echo -e ""
echo -e "${BLUE}📊 Math Plugin (Blue buttons):${NC}"
echo -e "  1. 'Calculate circle area (32cm)' - Should return area calculation"
echo -e "  2. 'Add 127 + 89' - Should return 216"
echo -e ""
echo -e "${YELLOW}📝 Text Plugin (Orange buttons):${NC}"
echo -e "  3. 'Uppercase text' - Should convert 'hello world' to 'HELLO WORLD'"
echo -e "  4. 'Count words' - Should count characters in the test phrase"
echo -e ""
echo -e "${GREEN}⏰ Time Plugin (Green buttons):${NC}"
echo -e "  5. 'Current time' - Should return current timestamp"
echo -e "  6. 'Today's date' - Should return today's date"
echo -e ""
echo -e "${RED}🛑 When finished testing, press ENTER to stop recording...${NC}"

# Wait for user to finish testing
read -p ""

# Stop recording
echo -e "${BLUE}🛑 Stopping video recording...${NC}"
kill $RECORDING_PID 2>/dev/null || true

# Wait for recording to finish
sleep 3

# Check if video was created
if [ -f "$VIDEO_FILE" ]; then
    VIDEO_SIZE=$(du -h "$VIDEO_FILE" | cut -f1)
    echo -e "${GREEN}✅ Video recording completed!${NC}"
    echo -e "${GREEN}📁 File: $VIDEO_FILE${NC}"
    echo -e "${GREEN}📊 Size: $VIDEO_SIZE${NC}"
    echo -e ""
    echo -e "${BLUE}🎬 To view the video:${NC}"
    echo -e "   open '$VIDEO_FILE'"
    echo -e ""
    echo -e "${BLUE}📱 To open the simulator directly:${NC}"
    echo -e "   xcrun simctl openurl '$DEVICE_ID' 'com.atsentia.sk-ios-demo'"
else
    echo -e "${RED}❌ Video recording failed${NC}"
    exit 1
fi

echo -e "${GREEN}🏁 Demo recording completed successfully!${NC}"