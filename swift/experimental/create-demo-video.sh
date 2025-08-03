#!/bin/bash

# Create Demo Video Script
# Uses the existing run-ios-demo.sh to launch the app, then records video

set -e

echo "🎬 Creating iOS Demo Video..."

# Configuration
VIDEO_FILE="sk-ios-demo-function-calling-$(date +%Y%m%d-%H%M%S).mp4"
DEVICE_ID="7A32A0CB-3DF5-4A63-AA3B-7713E799A904"  # Known working device from previous tests

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Using existing iOS Simulator setup...${NC}"
echo -e "${GREEN}🆔 Device ID: $DEVICE_ID${NC}"

# Ensure simulator is running
echo -e "${BLUE}📱 Starting iOS Simulator...${NC}"
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true

# Launch the app using existing script (run in background so we can continue)
echo -e "${BLUE}🚀 Launching sk-ios-demo using existing script...${NC}"
./run-ios-demo.sh &
LAUNCH_PID=$!

# Wait for app to launch
sleep 10

# Start video recording
echo -e "${GREEN}🎬 Starting video recording...${NC}"
rm -f "$VIDEO_FILE"
xcrun simctl io "$DEVICE_ID" recordVideo "$VIDEO_FILE" &
RECORDING_PID=$!

# Wait for recording to start
sleep 2

echo -e "${YELLOW}🎭 MANUAL DEMO INSTRUCTIONS${NC}"
echo -e "${YELLOW}===========================${NC}"
echo -e ""
echo -e "The iOS app is now running and being recorded."
echo -e "Please test the following buttons in order:"
echo -e ""
echo -e "${BLUE}1. Math Plugin (Blue buttons):${NC}"
echo -e "   • 'Calculate circle area (32cm)' → Should calculate π × (32/2)² ≈ 804.25"
echo -e "   • 'Add 127 + 89' → Should return 216"
echo -e ""
echo -e "${YELLOW}2. Text Plugin (Orange buttons):${NC}"
echo -e "   • 'Uppercase text' → Should convert 'hello world' to 'HELLO WORLD'"
echo -e "   • 'Count words' → Should count characters in test phrase"
echo -e ""
echo -e "${GREEN}3. Time Plugin (Green buttons):${NC}"
echo -e "   • 'Current time' → Should show current ISO timestamp"
echo -e "   • 'Today's date' → Should show today's date"
echo -e ""
echo -e "${RED}⏰ Allow 8-12 seconds after each tap for AI to respond${NC}"
echo -e "${RED}🛑 Press ENTER when finished to stop recording...${NC}"

# Wait for user to complete testing
read -p ""

# Stop recording
echo -e "${BLUE}🛑 Stopping video recording...${NC}"
kill $RECORDING_PID 2>/dev/null || true

# Stop the launch script
kill $LAUNCH_PID 2>/dev/null || true

# Wait for recording to finish
sleep 3

# Check results
if [ -f "$VIDEO_FILE" ]; then
    VIDEO_SIZE=$(du -h "$VIDEO_FILE" | cut -f1)
    echo -e "${GREEN}✅ Demo video created successfully!${NC}"
    echo -e "${GREEN}📁 File: $VIDEO_FILE${NC}"
    echo -e "${GREEN}📊 Size: $VIDEO_SIZE${NC}"
    echo -e ""
    echo -e "${BLUE}🎬 To view the video:${NC}"
    echo -e "   open '$VIDEO_FILE'"
    echo -e ""
    echo -e "${BLUE}📤 To share the video:${NC}"
    echo -e "   The video demonstrates all 6 function calling features:"
    echo -e "   • Math: Circle area calculation, Addition"
    echo -e "   • Text: Case conversion, Character counting"  
    echo -e "   • Time: Current timestamp, Today's date"
    echo -e ""
    echo -e "${GREEN}🎯 This video showcases Swift Semantic Kernel's complete${NC}"
    echo -e "${GREEN}   OpenAI function calling integration working perfectly!${NC}"
else
    echo -e "${RED}❌ Video recording failed${NC}"
    exit 1
fi

echo -e "${GREEN}🏁 Demo video creation completed!${NC}"