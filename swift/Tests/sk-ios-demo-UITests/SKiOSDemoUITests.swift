import XCTest

/// Automated UI Tests for Semantic Kernel iOS Demo
/// This test suite systematically tests all 6 function calling suggestion buttons
/// at human-like speed to create a comprehensive demo video.
final class SKiOSDemoUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"] // Optional: can be used to modify app behavior during testing
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app = nil
    }
    
    /// Test all 6 function calling suggestion buttons systematically
    /// This creates a comprehensive demo showing each plugin type working
    func testAllFunctionCallingSuggestions() throws {
        // Wait for app to fully load
        let headerText = app.staticTexts["Semantic Kernel initialized with Math, Text, and Time plugins"]
        XCTAssert(headerText.waitForExistence(timeout: 10), "App header should appear")
        
        // Wait a moment for the UI to settle
        sleep(2)
        
        // Test Math Plugin Functions (Blue buttons)
        testMathPluginFunctions()
        
        // Test Text Plugin Functions (Orange buttons) 
        testTextPluginFunctions()
        
        // Test Time Plugin Functions (Green buttons)
        testTimePluginFunctions()
        
        // Final pause to show completed state
        sleep(3)
    }
    
    // MARK: - Math Plugin Tests
    
    private func testMathPluginFunctions() {
        print("🔢 Testing Math Plugin Functions...")
        
        // Test 1: Calculate circle area
        testSuggestionButton(
            buttonText: "Calculate circle area (32cm)",
            expectedAction: "Calculate the area of a circle with diameter 32 cm using π × (d/2)²",
            pluginType: "Math",
            color: "Blue"
        )
        
        // Test 2: Add numbers
        testSuggestionButton(
            buttonText: "Add 127 + 89", 
            expectedAction: "Use the math.add function to calculate 127 + 89",
            pluginType: "Math",
            color: "Blue"
        )
    }
    
    // MARK: - Text Plugin Tests
    
    private func testTextPluginFunctions() {
        print("📝 Testing Text Plugin Functions...")
        
        // Test 3: Uppercase conversion
        testSuggestionButton(
            buttonText: "Uppercase text",
            expectedAction: "Use the text.upper function to convert 'hello world' to uppercase", 
            pluginType: "Text",
            color: "Orange"
        )
        
        // Test 4: Character counting
        testSuggestionButton(
            buttonText: "Count words",
            expectedAction: "Use the text.length function to count characters in 'The quick brown fox jumps over the lazy dog'",
            pluginType: "Text", 
            color: "Orange"
        )
    }
    
    // MARK: - Time Plugin Tests
    
    private func testTimePluginFunctions() {
        print("⏰ Testing Time Plugin Functions...")
        
        // Test 5: Current time
        testSuggestionButton(
            buttonText: "Current time",
            expectedAction: "Call the time.now function to get the current time",
            pluginType: "Time",
            color: "Green"
        )
        
        // Test 6: Today's date
        testSuggestionButton(
            buttonText: "Today's date", 
            expectedAction: "Call the time.today function to get today's date",
            pluginType: "Time",
            color: "Green"
        )
    }
    
    // MARK: - Helper Methods
    
    /// Test a suggestion button and wait for response
    private func testSuggestionButton(
        buttonText: String,
        expectedAction: String,
        pluginType: String,
        color: String
    ) {
        print("🧪 Testing \(pluginType) Plugin (\(color)): \(buttonText)")
        
        // Find and tap the suggestion button
        let suggestionButton = app.buttons[buttonText]
        XCTAssert(suggestionButton.waitForExistence(timeout: 5), 
                 "\(pluginType) suggestion button '\(buttonText)' should exist")
        
        // Human-like pause before tapping
        sleep(1)
        
        suggestionButton.tap()
        print("   ✅ Tapped: \(buttonText)")
        
        // Wait for message to appear in chat
        let messageText = app.staticTexts[expectedAction]
        XCTAssert(messageText.waitForExistence(timeout: 3),
                 "Expected message should appear: \(expectedAction)")
        
        // Wait for AI response (function calling takes time)
        sleep(8) // Allow time for OpenAI API call and function execution
        
        // Look for response indicators (typing indicator should disappear)
        let typingIndicator = app.staticTexts["AI is typing..."]
        
        // Wait for typing to finish (up to 15 seconds for API calls)
        var waitTime = 0
        while typingIndicator.exists && waitTime < 15 {
            sleep(1)
            waitTime += 1
        }
        
        print("   ✅ Response received for: \(buttonText)")
        
        // Human-like pause before next test
        sleep(2)
    }
    
    /// Test helper to capture screenshots for debugging
    private func captureScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Performance test to ensure app responds within reasonable time
    func testAppLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}