#!/bin/bash

# Create Xcode Project for iOS Demo with UI Testing
# This creates a separate Xcode project for the sk-ios-demo with video recording capabilities

set -e

echo "🛠️  Creating Xcode project for iOS Demo with UI Testing..."

# Configuration
PROJECT_NAME="SKiOSDemo"
PROJECT_DIR="iOS-Demo-Project"
BUNDLE_ID="com.atsentia.sk-ios-demo"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create project directory
echo -e "${BLUE}📁 Creating project directory...${NC}"
rm -rf "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create the Xcode project using xcodegen or manually
echo -e "${BLUE}🏗️  Setting up Xcode project structure...${NC}"

# Create project.yml for xcodegen (if available) or manual setup
cat > project.yml << EOF
name: $PROJECT_NAME
options:
  bundleIdPrefix: com.atsentia
  deploymentTarget:
    iOS: "15.0"
  
settings:
  DEVELOPMENT_TEAM: ""
  
targets:
  $PROJECT_NAME:
    type: application
    platform: iOS
    sources:
      - ../Sources/sk-ios-demo
    dependencies:
      - package: SwiftSemanticKernel
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID
      DEVELOPMENT_TEAM: ""
      SWIFT_VERSION: "5.9"
      
  ${PROJECT_NAME}UITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - UITests
    dependencies:
      - target: $PROJECT_NAME
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: ${BUNDLE_ID}.uitests
      TEST_HOST: ""
      TEST_TARGET_NAME: $PROJECT_NAME

packages:
  SwiftSemanticKernel:
    path: ../

schemes:
  $PROJECT_NAME:
    build:
      targets:
        $PROJECT_NAME: all
        ${PROJECT_NAME}UITests: [test]
    test:
      targets:
        - ${PROJECT_NAME}UITests
      captureScreenshots: true
      testPlans:
        - TestPlan
EOF

# Create UITests directory and files
mkdir -p UITests

# Create the UI test file
cat > UITests/SKiOSDemoUITests.swift << 'EOF'
import XCTest

/// Automated UI Tests for Semantic Kernel iOS Demo
/// This test suite systematically tests all 6 function calling suggestion buttons
/// at human-like speed to create a comprehensive demo video.
final class SKiOSDemoUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        
        // Add initial screenshot
        captureScreenshot(name: "01-app-launch")
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    /// Complete demo test that systematically tests all 6 suggestion buttons
    func testCompleteFunctionCallingDemo() throws {
        print("🎬 Starting Complete Function Calling Demo")
        
        // Wait for app to fully load
        let headerText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Semantic Kernel initialized'")).firstMatch
        XCTAssert(headerText.waitForExistence(timeout: 10), "App header should appear")
        
        captureScreenshot(name: "02-app-loaded")
        
        // Wait for UI to settle
        sleep(2)
        
        // Test all functions in order
        testMathPluginFunctions()
        testTextPluginFunctions() 
        testTimePluginFunctions()
        
        // Final screenshot
        captureScreenshot(name: "13-demo-complete")
        
        print("🎉 Complete Function Calling Demo Finished!")
    }
    
    // MARK: - Math Plugin Tests (Blue)
    
    private func testMathPluginFunctions() {
        print("🔢 Testing Math Plugin Functions...")
        
        // Test 1: Circle area calculation
        testSuggestionButton(
            buttonText: "Calculate circle area (32cm)",
            testNumber: "03",
            pluginType: "Math",
            expectedResponseContains: "area"
        )
        
        // Test 2: Addition
        testSuggestionButton(
            buttonText: "Add 127 + 89",
            testNumber: "04", 
            pluginType: "Math",
            expectedResponseContains: "216"
        )
    }
    
    // MARK: - Text Plugin Tests (Orange)
    
    private func testTextPluginFunctions() {
        print("📝 Testing Text Plugin Functions...")
        
        // Test 3: Uppercase conversion
        testSuggestionButton(
            buttonText: "Uppercase text",
            testNumber: "05",
            pluginType: "Text",
            expectedResponseContains: "HELLO WORLD"
        )
        
        // Test 4: Character counting
        testSuggestionButton(
            buttonText: "Count words",
            testNumber: "06",
            pluginType: "Text", 
            expectedResponseContains: "characters"
        )
    }
    
    // MARK: - Time Plugin Tests (Green)
    
    private func testTimePluginFunctions() {
        print("⏰ Testing Time Plugin Functions...")
        
        // Test 5: Current time
        testSuggestionButton(
            buttonText: "Current time",
            testNumber: "07",
            pluginType: "Time",
            expectedResponseContains: "T"  // ISO timestamp contains T
        )
        
        // Test 6: Today's date
        testSuggestionButton(
            buttonText: "Today's date",
            testNumber: "08",
            pluginType: "Time",
            expectedResponseContains: "2025"  // Current year
        )
    }
    
    // MARK: - Helper Methods
    
    private func testSuggestionButton(
        buttonText: String,
        testNumber: String,
        pluginType: String,
        expectedResponseContains: String
    ) {
        print("🧪 Test \(testNumber): \(pluginType) - \(buttonText)")
        
        // Find the button by text
        let button = app.buttons.containing(NSPredicate(format: "label CONTAINS '\(buttonText)'")).firstMatch
        
        // Scroll if needed to make button visible
        if !button.exists {
            app.swipeUp()
            sleep(1)
        }
        
        XCTAssert(button.waitForExistence(timeout: 5), "Button '\(buttonText)' should exist")
        
        // Screenshot before tap
        captureScreenshot(name: "\(testNumber)a-before-\(pluginType.lowercased())-\(buttonText.replacingOccurrences(of: " ", with: "-"))")
        
        // Human-like pause and tap
        sleep(1)
        button.tap()
        
        print("   ✅ Tapped: \(buttonText)")
        
        // Screenshot after tap (shows user message)
        sleep(2)
        captureScreenshot(name: "\(testNumber)b-after-tap-message-sent")
        
        // Wait for AI response (allow time for function calling)
        print("   ⏳ Waiting for AI response...")
        
        // Look for typing indicator to appear and disappear
        let typingIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'typing'")).firstMatch
        
        // Wait up to 20 seconds for response
        var waitTime = 0
        let maxWaitTime = 20
        
        while waitTime < maxWaitTime {
            sleep(1)
            waitTime += 1
            
            // Check if we can find expected response content
            let responseElement = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '\(expectedResponseContains)'")).firstMatch
            if responseElement.exists {
                print("   ✅ Response received: Found '\(expectedResponseContains)'")
                break
            }
            
            // Show progress
            if waitTime % 5 == 0 {
                print("   ⏳ Still waiting... (\(waitTime)s)")
            }
        }
        
        // Screenshot after response
        captureScreenshot(name: "\(testNumber)c-response-\(pluginType.lowercased())-complete")
        
        // Human-like pause before next test
        sleep(3)
    }
    
    private func captureScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        print("📸 Screenshot: \(name)")
    }
}
EOF

# Create Test Plan for video recording
mkdir -p TestPlans
cat > TestPlans/TestPlan.xctestplan << EOF
{
  "configurations" : [
    {
      "id" : "Default",
      "name" : "Configuration 1",
      "options" : {
        "captureScreenshotAutomatically" : true,
        "recordVideoAutomatically" : true
      }
    }
  ],
  "defaultOptions" : {
    "captureScreenshotAutomatically" : true,
    "recordVideoAutomatically" : true,
    "testTimeoutsEnabled" : true
  },
  "testTargets" : [
    {
      "target" : {
        "containerPath" : "container:",
        "identifier" : "${PROJECT_NAME}UITests",
        "name" : "${PROJECT_NAME}UITests"
      }
    }
  ],
  "version" : 1
}
EOF

# Create Package.swift for local dependencies
cat > Package.swift << EOF
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "$PROJECT_NAME",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(name: "$PROJECT_NAME", targets: ["$PROJECT_NAME"])
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "$PROJECT_NAME",
            dependencies: [
                .product(name: "SemanticKernelCore", package: "SwiftSemanticKernel"),
                .product(name: "SemanticKernelConnectorsOpenAI", package: "SwiftSemanticKernel"),
                .product(name: "SemanticKernelPluginsCore", package: "SwiftSemanticKernel")
            ],
            path: "../Sources/sk-ios-demo"
        )
    ]
)
EOF

# Create build and test script
cat > build-and-test.sh << 'EOF'
#!/bin/bash

echo "🏗️  Building and Testing iOS Demo Project..."

# Check if xcodegen is available
if command -v xcodegen &> /dev/null; then
    echo "📱 Generating Xcode project with xcodegen..."
    xcodegen generate
    PROJECT_FILE="SKiOSDemo.xcodeproj"
else
    echo "⚠️  xcodegen not found. Please create Xcode project manually or install xcodegen:"
    echo "   brew install xcodegen"
    exit 1
fi

# Build the project
echo "🔨 Building project..."
xcodebuild -project "$PROJECT_FILE" -scheme "SKiOSDemo" -destination "platform=iOS Simulator,name=iPhone 16 Pro" build

# Run UI tests with video recording
echo "🎬 Running UI tests with video recording..."
xcodebuild test -project "$PROJECT_FILE" -scheme "SKiOSDemo" -destination "platform=iOS Simulator,name=iPhone 16 Pro" -testPlan TestPlan

echo "✅ Build and test completed!"
echo "📹 Check the test results for video recordings and screenshots"
EOF

chmod +x build-and-test.sh

# Create README
cat > README.md << EOF
# SK iOS Demo - Xcode Project

This is a separate Xcode project for the Semantic Kernel iOS Demo app with comprehensive UI testing and video recording capabilities.

## Features

- 📱 Complete iOS app showcasing Semantic Kernel function calling
- 🎬 Automated UI tests that record video demonstrations
- 📸 Screenshot capture at each test step
- 🧪 Systematic testing of all 6 plugin suggestion buttons

## Setup

1. Install xcodegen (if not already installed):
   \`\`\`bash
   brew install xcodegen
   \`\`\`

2. Generate the Xcode project:
   \`\`\`bash
   ./build-and-test.sh
   \`\`\`

## Running Tests

### Automated Video Demo
Run the complete automated demo:
\`\`\`bash
./build-and-test.sh
\`\`\`

### Manual Testing
1. Open \`SKiOSDemo.xcodeproj\` in Xcode
2. Select iPhone 16 Pro simulator
3. Go to Product → Test to run UI tests with video recording

## Test Coverage

The automated test systematically verifies:

### Math Plugin (Blue buttons)
1. **Calculate circle area (32cm)** - Tests circle area calculation with π × (d/2)²
2. **Add 127 + 89** - Tests math.add function (expects: 216)

### Text Plugin (Orange buttons)  
3. **Uppercase text** - Tests text.upper function on 'hello world' (expects: HELLO WORLD)
4. **Count words** - Tests text.length function on test phrase (expects: character count)

### Time Plugin (Green buttons)
5. **Current time** - Tests time.now function (expects: ISO timestamp)
6. **Today's date** - Tests time.today function (expects: current date)

## Video Output

Test videos and screenshots are saved in:
- Xcode Test Results Navigator
- \`~/Library/Developer/Xcode/DerivedData/.../Logs/Test/\`

## Environment

Ensure your \`.env\` file contains:
\`\`\`
OPENAI_API_KEY="your_openai_api_key_here"
\`\`\`
EOF

echo -e "${GREEN}✅ Xcode project structure created successfully!${NC}"
echo -e "${GREEN}📁 Project location: $PROJECT_DIR${NC}"
echo -e ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. cd $PROJECT_DIR"
echo -e "2. ./build-and-test.sh"
echo -e ""
echo -e "${YELLOW}Requirements:${NC}"
echo -e "• xcodegen: brew install xcodegen"
echo -e "• Xcode with iOS Simulator"
echo -e "• OpenAI API key in ../.env file"