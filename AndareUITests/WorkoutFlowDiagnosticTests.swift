//
//  WorkoutFlowDiagnosticTests.swift
//  AndareUITests
//
//  Throwaway walkthrough: start a workout, pass the guide/permissions,
//  reach the active screen, expand the gyro panel, hold-to-stop.
//

import XCTest

final class WorkoutFlowDiagnosticTests: XCTestCase {

    @MainActor
    func testStartWorkoutToActiveScreen() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        // Tap the big start button
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.43)).tap()
        sleep(2)
        attach(app, "1-after-start-tap")

        // Guide screen 1: placement
        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 3) {
            attach(app, "1b-guide-placement")
            continueButton.tap()
            sleep(1)
        }

        let letsGo = app.buttons["Let's Go"]
        if letsGo.waitForExistence(timeout: 3) {
            // Grant buttons in the guide (location may already be granted via simctl)
            var safety = 0
            while app.buttons["Grant"].firstMatch.exists && safety < 3 {
                app.buttons["Grant"].firstMatch.tap()
                safety += 1
                sleep(2)

                // System location alert
                let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                for label in ["Allow While Using App", "Allow Once"] {
                    let btn = springboard.buttons[label]
                    if btn.waitForExistence(timeout: 2) { btn.tap(); break }
                }

                // HealthKit access sheet
                let turnOnAll = app.staticTexts["Turn On All"]
                if turnOnAll.waitForExistence(timeout: 3) {
                    turnOnAll.tap()
                    sleep(1)
                    let allow = app.buttons["Allow"]
                    if allow.waitForExistence(timeout: 2) { allow.tap() }
                    sleep(1)
                }
                attach(app, "2-after-grant-\(safety)")
            }

            attach(app, "3-guide-before-letsgo")
            if letsGo.isEnabled { letsGo.tap() }
            sleep(1)
        }

        // Countdown: tap anywhere to skip
        attach(app, "4-countdown")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        sleep(3)
        attach(app, "5-active-screen")

        // Expand the gyro panel by swiping down on the stats area
        let swipeStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        let swipeEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        swipeStart.press(forDuration: 0.05, thenDragTo: swipeEnd)
        sleep(2)
        attach(app, "6-gyro-panel")

        // Quick tap on the stop button (should nudge, not stop)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.94)).tap()
        sleep(1)
        attach(app, "7-stop-tap-nudge")

        // Hold to stop
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.94)).press(forDuration: 2.0)
        sleep(3)
        attach(app, "8-after-hold-stop")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
