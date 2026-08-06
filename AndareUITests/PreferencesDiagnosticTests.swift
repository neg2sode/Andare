//
//  PreferencesDiagnosticTests.swift
//  AndareUITests
//
//  Walkthrough for the Preferences sheet: editable profile rows with the
//  Apple Health sync indicator, and the notification info buttons.
//

import XCTest

final class PreferencesDiagnosticTests: XCTestCase {

    @MainActor
    func testPreferencesWalkthrough() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        // Expand the drawer, then open Preferences via the gear.
        let grabber = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93))
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
        grabber.press(forDuration: 0.05, thenDragTo: top)
        sleep(2)

        app.buttons["Preferences"].firstMatch.tap()
        sleep(2)
        attach(app, "1-preferences")

        // Profile rows are editable: focus weight, type, dismiss the keyboard.
        let weightField = app.textFields.element(boundBy: 0)
        XCTAssertTrue(weightField.waitForExistence(timeout: 5), "profile weight field missing")
        weightField.tap()
        sleep(1)
        attach(app, "2-keyboard-with-done")

        weightField.typeText("2")
        attach(app, "3-typing")

        // Two buttons are labelled "Done": the sheet header and the keyboard
        // toolbar. The keyboard one sits lowest on screen.
        let doneButtons = app.buttons.matching(identifier: "Done").allElementsBoundByIndex
        guard let keyboardDone = doneButtons.max(by: { $0.frame.minY < $1.frame.minY }) else {
            return XCTFail("no Done button while editing")
        }
        XCTAssertGreaterThan(doneButtons.count, 1, "keyboard toolbar Done missing")
        keyboardDone.tap()
        sleep(2)
        attach(app, "4-after-blur-sync")

        // Turn on Real-Time Alerts so the Frequency row appears.
        let realTime = app.switches.element(boundBy: 1)
        if realTime.exists { realTime.tap() }
        sleep(1)
        attach(app, "5-frequency-row")

        // Info buttons present explanations through AlertManager.
        let info = app.buttons["About Real-Time Alerts"]
        if info.waitForExistence(timeout: 3) {
            info.tap()
            sleep(2)
            attach(app, "6-info-alert")
            app.buttons["OK"].firstMatch.tap()
            sleep(1)
        } else {
            XCTFail("info button for Real-Time Alerts not found")
        }

        attach(app, "7-final")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
