//
//  DrawerScopeUITests.swift
//  AndareUITests
//
//  The drawer title is the scope control. Switching it must change every
//  section at once — the whole point of replacing the old arrangement, where a
//  "Today" panel, a seven-day summary and a self-retitling workout list each
//  described a different window without saying so.
//

import XCTest

final class DrawerScopeUITests: XCTestCase {

    @MainActor
    func testScopeMenuSwitchesEverySection() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        expandDrawer(app)

        // Today scope is the launch default.
        let scopeButton = app.buttons["Time period"]
        XCTAssertTrue(scopeButton.waitForExistence(timeout: 5), "no scope control in the drawer title")
        attach(app, "1-today-scope")

        XCTAssertTrue(app.staticTexts["Time in Daylight"].exists,
                      "the daylight tile should use its plain label in Today scope")

        // The Show More button is gone for good; scope replaced it.
        XCTAssertFalse(app.buttons["Show More"].exists, "Show More survived in Today scope")

        // Switch to This Week.
        scopeButton.tap()
        sleep(1)
        app.buttons["This Week"].firstMatch.tap()
        sleep(2)
        attach(app, "2-week-scope")

        // Daylight defaults to a daily average over a week, so its caption
        // changes rather than the number silently swapping under a fixed label.
        XCTAssertTrue(app.staticTexts["Daily Avg. Daylight"].waitForExistence(timeout: 5),
                      "the daylight tile did not switch to its week variant")
        XCTAssertFalse(app.buttons["Show More"].exists, "Show More survived in Week scope")
    }

    /// Collapsed, the title bar is 100pt tall and is what the user taps to open
    /// the drawer — a live menu there would swallow that tap.
    @MainActor
    func testTitleIsNotTappableWhileCollapsed() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        XCTAssertFalse(app.buttons["Time period"].exists,
                       "the scope menu must be inert while the drawer is collapsed")

        expandDrawer(app)
        XCTAssertTrue(app.buttons["Time period"].waitForExistence(timeout: 5),
                      "the scope menu should appear once the drawer is open")
    }

    /// Scope follows the same rule the drawer already applied to its expanded
    /// workout list: closing it forgets the state.
    @MainActor
    func testCollapsingResetsScopeToToday() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        expandDrawer(app)
        app.buttons["Time period"].tap()
        sleep(1)
        app.buttons["This Week"].firstMatch.tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Daily Avg. Daylight"].waitForExistence(timeout: 5))

        collapseDrawer(app)
        expandDrawer(app)

        XCTAssertTrue(app.staticTexts["Time in Daylight"].waitForExistence(timeout: 5),
                      "scope should have reset to Today after the drawer closed")
    }

    // MARK: - Helpers

    @MainActor
    private func expandDrawer(_ app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93))
            .press(forDuration: 0.05,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        sleep(2)
    }

    @MainActor
    private func collapseDrawer(_ app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
            .press(forDuration: 0.05,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)))
        sleep(2)
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
