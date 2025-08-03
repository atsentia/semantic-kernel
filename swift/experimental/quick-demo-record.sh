#!/bin/bash

# Quick Demo Recording Script
# Uses screen recording instead of simctl for better compatibility

set -e

echo "🎬 Quick iOS Demo Screen Recording..."

# Configuration
VIDEO_FILE="sk-ios-demo-screen-$(date +%Y%m%d-%H%M%S).mov"
DEVICE_ID="7A32A0CB-3DF5-4A63-AA3B-7713E799A904"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}📱 Using iOS Simulator screen recording...${NC}"

# Ensure simulator is running
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true

# Launch the app if not running
if ! xcrun simctl list apps "$DEVICE_ID" | grep -q "com.semantickernel.sk-ios-demo"; then
    echo -e "${BLUE}🚀 Launching app...${NC}"
    # Use the existing successful method
    ./run-ios-demo.sh &
    sleep 10
fi

echo -e "${GREEN}🎬 Starting screen recording...${NC}"
echo -e "${YELLOW}This will record your entire screen for 3 minutes${NC}"
echo -e "${YELLOW}Focus on the iOS Simulator and test the 6 buttons${NC}"
echo -e ""
echo -e "${BLUE}Test these in order:${NC}"
echo -e "1. Calculate circle area (32cm) - Blue"
echo -e "2. Add 127 + 89 - Blue" 
echo -e "3. Uppercase text - Orange"
echo -e "4. Count words - Orange"
echo -e "5. Current time - Green"
echo -e "6. Today's date - Green"
echo -e ""
echo -e "${RED}Press SPACE to start recording, then ESC to stop${NC}"

# Use native macOS screen recording (more reliable)
xcrun simctl io "$DEVICE_ID" screenshot initial-state.png
echo -e "${GREEN}📸 Screenshot saved as initial-state.png${NC}"

# Alternative: Use screencapture for the whole screen
echo -e "${YELLOW}Recording will start in 3 seconds...${NC}"
sleep 3

# Record for 3 minutes or until stopped
timeout 180 xcrun simctl io "$DEVICE_ID" recordVideo "$VIDEO_FILE" || echo "Recording completed"

echo -e "${GREEN}✅ Recording finished!${NC}"

if [ -f "$VIDEO_FILE" ]; then
    VIDEO_SIZE=$(du -h "$VIDEO_FILE" | cut -f1)
    echo -e "${GREEN}📁 File: $VIDEO_FILE${NC}"
    echo -e "${GREEN}📊 Size: $VIDEO_SIZE${NC}"
    
    # Try to open it
    open "$VIDEO_FILE"
else
    echo -e "${RED}❌ Recording failed${NC}"
fi