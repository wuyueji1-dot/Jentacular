//
//  ScreenshotUITests.swift
//  JentacularUITests
//
//  UI tests for capturing App Store screenshots.
//  Supports English and Russian via APP_LANGUAGE environment variable.
//

import XCTest

class ScreenshotUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Configure language from environment
        let language = ProcessInfo.processInfo.environment["APP_LANGUAGE"] ?? "en"
        let locale = language == "ru" ? "ru_RU" : "en_US"
        app.launchArguments += ["-AppleLanguages", "(\(language))"]
        app.launchArguments += ["-AppleLocale", locale]

        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Main test

    func testCaptureAllScreens() throws {
        // Handle onboarding / privacy consent if present
        handleOnboardingIfNeeded()

        // Wait for tab bar
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 15), "Tab bar did not appear")

        let tabNames = ["01_Home", "02_Shield", "03_Servers", "04_Analysis", "05_Settings"]
        let buttons = tabBar.buttons.allElementsBoundByIndex

        for (index, name) in tabNames.enumerated() {
            guard index < buttons.count else { break }
            buttons[index].tap()
            // Wait for view to settle
            sleep(3)
            captureScreenshot(named: name)
        }
    }

    // MARK: - Helpers

    private func handleOnboardingIfNeeded() {
        // Wait a moment for onboarding to appear
        sleep(3)

        // Try to find and tap accept / agree / continue buttons
        let predicates = [
            "label CONTAINS[c] 'accept'",
            "label CONTAINS[c] 'agree'",
            "label CONTAINS[c] 'continue'",
            "label CONTAINS[c] 'get started'",
            "label CONTAINS[c] 'принять'",
            "label CONTAINS[c] 'соглас'",
            "label CONTAINS[c] 'продолжить'",
            "label CONTAINS[c] 'начать'"
        ]

        for predicate in predicates {
            let button = app.buttons.matching(NSPredicate(format: predicate)).firstMatch
            if button.exists && button.isHittable {
                button.tap()
                sleep(2)
                break
            }
        }

        // If there's a scrollable onboarding, try swiping up
        if !app.tabBars.element.exists {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            for _ in 0..<3 {
                start.press(forDuration: 0.1, thenDragTo: end)
                sleep(1)
            }
            // Try accept button again after swipe
            for predicate in predicates {
                let button = app.buttons.matching(NSPredicate(format: predicate)).firstMatch
                if button.exists && button.isHittable {
                    button.tap()
                    sleep(2)
                    break
                }
            }
        }
    }

    private func captureScreenshot(named name: String) {
        let language = ProcessInfo.processInfo.environment["APP_LANGUAGE"] ?? "en"
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(language)_\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        print("📸 Captured: \(language)_\(name)")
    }
}
