import XCTest

class AppTourUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set launch arguments to ensure fresh state
        app.launchArguments = ["UI_TESTING", "RESET_APP_TOUR"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Tour Trigger Tests
    
    func testAppTourAppearsForNewUser() throws {
        // Complete onboarding flow first
        completeOnboardingFlow()
        
        // Wait for dashboard to appear
        let dashboardTitle = app.staticTexts["Today"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5))
        
        // Verify tour overlay appears
        let tourOverlay = app.otherElements["AppTourOverlay"]
        XCTAssertTrue(tourOverlay.waitForExistence(timeout: 3))
        
        // Verify skip button is visible
        let skipButton = app.buttons["Skip"]
        XCTAssertTrue(skipButton.exists)
        
        // Verify progress indicator
        let progressText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Step'")).firstMatch
        XCTAssertTrue(progressText.exists)
    }
    
    func testAppTourDoesNotAppearForReturningUser() throws {
        // Set user defaults to simulate returning user
        app.launchArguments = ["UI_TESTING", "MARK_TOUR_COMPLETED"]
        app.launch()
        
        // Complete login
        completeLogin()
        
        // Wait for dashboard
        let dashboardTitle = app.staticTexts["Today"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5))
        
        // Verify tour does not appear
        let tourOverlay = app.otherElements["AppTourOverlay"]
        XCTAssertFalse(tourOverlay.waitForExistence(timeout: 2))
    }
    
    // MARK: - Tour Navigation Tests
    
    func testSkipTour() throws {
        // Complete onboarding and wait for tour
        completeOnboardingFlow()
        waitForTour()
        
        // Tap skip button
        let skipButton = app.buttons["Skip"]
        skipButton.tap()
        
        // Verify tour disappears
        let tourOverlay = app.otherElements["AppTourOverlay"]
        XCTAssertFalse(tourOverlay.waitForExistence(timeout: 2))
        
        // Verify dashboard is accessible
        let dashboardTitle = app.staticTexts["Today"]
        XCTAssertTrue(dashboardTitle.exists)
    }
    
    func testCompleteTour() throws {
        // Test navigation through dashboard tour steps (Story 20.2)
        
        completeOnboardingFlow()
        waitForTour()
        
        // Verify we're on step 1 - Dashboard overview
        let step1Progress = app.staticTexts["Step 1 of 7"]
        XCTAssertTrue(step1Progress.exists)
        
        // Verify dashboard overview content
        let dashboardTitle = app.staticTexts["Your Daily Dashboard"]
        XCTAssertTrue(dashboardTitle.exists)
        
        let dashboardDescription = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Start each day here'")).firstMatch
        XCTAssertTrue(dashboardDescription.exists)
        
        // Tap Next to go to step 2
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.exists)
        nextButton.tap()
        
        // Verify we're on step 2 - Today's Focus
        let step2Progress = app.staticTexts["Step 2 of 7"]
        XCTAssertTrue(step2Progress.waitForExistence(timeout: 2))
        
        let todaysFocusTitle = app.staticTexts["Today's Focus"]
        XCTAssertTrue(todaysFocusTitle.exists)
        
        let todaysFocusDescription = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'daily practice recommendation'")).firstMatch
        XCTAssertTrue(todaysFocusDescription.exists)
        
        // Tap Next to go to step 3
        XCTAssertTrue(nextButton.exists)
        nextButton.tap()
        
        // Verify we're on step 3 - Weekly progress
        let step3Progress = app.staticTexts["Step 3 of 7"]
        XCTAssertTrue(step3Progress.waitForExistence(timeout: 2))
        
        let progressTitle = app.staticTexts["Weekly Progress"]
        XCTAssertTrue(progressTitle.exists)
        
        let progressDescription = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Monitor your streak'")).firstMatch
        XCTAssertTrue(progressDescription.exists)
    }
    
    func testDashboardTourHighlights() throws {
        // Test that dashboard elements are properly highlighted during tour
        
        completeOnboardingFlow()
        waitForTour()
        
        // Verify tour overlay is active
        let tourOverlay = app.otherElements["AppTourOverlay"]
        XCTAssertTrue(tourOverlay.exists)
        
        // Check that the coach mark is visible
        let coachMark = app.otherElements["CoachMark"]
        XCTAssertTrue(coachMark.waitForExistence(timeout: 2))
        
        // Verify step 1 content
        let welcomeTitle = app.staticTexts["Your Daily Dashboard"]
        XCTAssertTrue(welcomeTitle.exists)
        
        // Move to next step (step 2 - Today's Focus)
        app.buttons["Next"].tap()
        
        // Verify step 2 highlights today's focus
        let todaysFocusTitle = app.staticTexts["Today's Focus"]
        XCTAssertTrue(todaysFocusTitle.waitForExistence(timeout: 2))
        
        // Move to next step (step 3 - Weekly Progress)
        app.buttons["Next"].tap()
        
        // Verify step 3 highlights weekly progress
        let progressTitle = app.staticTexts["Weekly Progress"]
        XCTAssertTrue(progressTitle.waitForExistence(timeout: 2))
    }
    
    func testRoutinesTabTourStep() throws {
        // Test the routines tab tour step (Story 20.3) and practice tab tour step (Story 20.4)
        
        completeOnboardingFlow()
        waitForTour()
        
        // Navigate through dashboard steps to reach routines step
        // Step 1: Dashboard overview
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.exists)
        nextButton.tap()
        
        // Step 2: Today's Focus
        XCTAssertTrue(nextButton.waitForExistence(timeout: 2))
        nextButton.tap()
        
        // Step 3: Weekly progress
        XCTAssertTrue(nextButton.waitForExistence(timeout: 2))
        nextButton.tap()
        
        // Step 4: Routines tab
        let step4Progress = app.staticTexts["Step 4 of 7"]
        XCTAssertTrue(step4Progress.waitForExistence(timeout: 2))
        
        // Verify routines tour content
        let routinesTitle = app.staticTexts["Structured Programs"]
        XCTAssertTrue(routinesTitle.exists)
        
        let routinesDescription = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Explore the \\'Routines\\' tab'")).firstMatch
        XCTAssertTrue(routinesDescription.exists)
        
        // Verify "Next" button on routines step (not last step anymore)
        XCTAssertTrue(nextButton.exists)
        nextButton.tap()
        
        // Step 5: Practice tab
        let step5Progress = app.staticTexts["Step 5 of 7"]
        XCTAssertTrue(step5Progress.waitForExistence(timeout: 2))
        
        // Verify practice tour content
        let practiceTitle = app.staticTexts["Quick Practice"]
        XCTAssertTrue(practiceTitle.exists)
        
        let practiceDescription = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Want to do a quick'")).firstMatch
        XCTAssertTrue(practiceDescription.exists)
        
        // Verify "Next" button on practice step
        XCTAssertTrue(nextButton.exists)
        nextButton.tap()
        
        // Step 6: Progress tab
        let step6Progress = app.staticTexts["Step 6 of 7"]
        XCTAssertTrue(step6Progress.waitForExistence(timeout: 2))
        
        // Verify progress tour content
        let progressTabTitle = app.staticTexts["Track Your Journey"]
        XCTAssertTrue(progressTabTitle.exists)
        
        let progressTabDescription = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Track your journey'")).firstMatch
        XCTAssertTrue(progressTabDescription.exists)
        
        // Verify "Next" button on progress step
        XCTAssertTrue(nextButton.exists)
        nextButton.tap()
        
        // Step 7: Learn tab
        let step7Progress = app.staticTexts["Step 7 of 7"]
        XCTAssertTrue(step7Progress.waitForExistence(timeout: 2))
        
        // Verify learn tour content
        let learnTabTitle = app.staticTexts["Have Questions?"]
        XCTAssertTrue(learnTabTitle.exists)
        
        let learnTabDescription = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'AI \\'Coach\\' is here to help'")).firstMatch
        XCTAssertTrue(learnTabDescription.exists)
        
        // Verify "Done" button appears on last step
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists)
        
        // Complete tour
        doneButton.tap()
        
        // Verify tour disappears
        let tourOverlay = app.otherElements["AppTourOverlay"]
        XCTAssertFalse(tourOverlay.waitForExistence(timeout: 2))
    }
    
    // MARK: - Visual Tests
    
    func testTourOverlayDimsBackground() throws {
        completeOnboardingFlow()
        waitForTour()
        
        // Take screenshot for visual verification
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Tour_Overlay_Active"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testTourWorksOnDifferentScreenSizes() throws {
        // This test should be run on different simulators
        completeOnboardingFlow()
        waitForTour()
        
        // Verify tour elements are visible
        let skipButton = app.buttons["Skip"]
        XCTAssertTrue(skipButton.isHittable)
        
        let progressIndicator = app.otherElements["TourProgressIndicator"]
        if progressIndicator.exists {
            XCTAssertTrue(progressIndicator.frame.minY > 0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func completeOnboardingFlow() {
        // Simplified onboarding completion for testing
        // This assumes a test mode that bypasses full onboarding
        
        // Skip splash if present
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 2) {
            getStartedButton.tap()
        }
        
        // Continue through any remaining onboarding steps
        let continueButton = app.buttons.matching(identifier: "Continue").firstMatch
        while continueButton.waitForExistence(timeout: 1) {
            if continueButton.isHittable {
                continueButton.tap()
            } else {
                break
            }
        }
        
        // Complete final onboarding
        let completionButton = app.buttons["Continue to Dashboard"]
        if completionButton.waitForExistence(timeout: 3) {
            completionButton.tap()
        }
    }
    
    private func completeLogin() {
        // Login with test credentials
        let emailField = app.textFields["Email"]
        if emailField.waitForExistence(timeout: 3) {
            emailField.tap()
            emailField.typeText("test@example.com")
            
            let passwordField = app.secureTextFields["Password"]
            passwordField.tap()
            passwordField.typeText("testpassword")
            
            app.buttons["Sign In"].tap()
        }
    }
    
    private func waitForTour() {
        let tourOverlay = app.otherElements["AppTourOverlay"]
        XCTAssertTrue(tourOverlay.waitForExistence(timeout: 5), "Tour overlay did not appear")
    }
}