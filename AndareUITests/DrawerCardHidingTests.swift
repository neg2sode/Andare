//
//  DrawerCardHidingTests.swift
//  AndareUITests
//
//  Long-pressing an informational drawer card hides it, tells the user where
//  to get it back, and the Preferences toggle restores it.
//

import XCTest

final class DrawerCardHidingTests: XCTestCase {

    @MainActor
    func testLongPressHidesTodayAndPreferencesRestoresIt() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        // Expand the drawer.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93))
            .press(forDuration: 0.05,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        sleep(2)

        let todayHeader = app.staticTexts["Today"]
        XCTAssertTrue(todayHeader.waitForExistence(timeout: 5), "Today section missing at launch")
        attach(app, "1-drawer-with-today")

        // Long-press the Today card to hide it.
        todayHeader.press(forDuration: 0.8)
        sleep(2)
        attach(app, "2-hidden-note")

        // The note names where to restore it, then dismisses.
        XCTAssertTrue(app.staticTexts["Today Hidden"].exists, "no note explaining the hide")
        app.buttons["OK"].firstMatch.tap()
        sleep(1)
        XCTAssertFalse(todayHeader.exists, "Today should be hidden after the long press")
        attach(app, "3-today-hidden")

        // Preferences → Drawer → Today brings it back.
        app.buttons["Preferences"].firstMatch.tap()
        sleep(2)
        let toggle = app.switches["Today"]
        var attempts = 0
        while !toggle.isHittable && attempts < 8 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "Drawer toggle for Today missing")
        attach(app, "4-preferences-drawer-section")
        toggle.tap()
        sleep(1)

        app.buttons["Done"].firstMatch.tap()
        sleep(2)
        XCTAssertTrue(todayHeader.waitForExistence(timeout: 5), "Today should be restored")
        attach(app, "5-today-restored")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
