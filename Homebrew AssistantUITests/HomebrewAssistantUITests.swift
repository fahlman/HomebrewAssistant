//
//  HomebrewAssistantUITests.swift
//  Homebrew Assistant UI Tests
//
//  Purpose: Provides a minimal UI smoke test for the app launch path.
//

import XCTest

@MainActor
final class HomebrewAssistantUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAppLaunchesToDiskAccess() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.buttons["bottom.quit"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["bottom.next"].exists)
    }
}
