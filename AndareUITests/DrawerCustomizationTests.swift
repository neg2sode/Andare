//
//  DrawerCustomizationTests.swift
//  AndareUITests
//
//  Long-pressing the tile grid opens the editor, where tiles can be added,
//  removed and reordered. Replaces the older long-press-to-hide behaviour,
//  which could only remove whole sections and only via Preferences to restore.
//

import XCTest

final class DrawerCustomizationTests: XCTestCase {

    @MainActor
    func testRemovingATileTakesItOutOfTheDrawerAndAddingPutsItBack() throws {
        let app = launch()
        expandDrawer(app)

        // The default layout is the whole catalog.
        XCTAssertTrue(app.staticTexts["Time in Daylight"].waitForExistence(timeout: 5),
                      "default layout should include the daylight tile")
        XCTAssertTrue(app.staticTexts["Walking Distance"].exists,
                      "default layout should include every tile")
        attach(app, "1-default-layout")

        openEditor(app)
        attach(app, "2-editor")

        // One tap removes — no swipe, no confirming second tap.
        app.buttons["Remove Walking Distance"].firstMatch.tap()
        sleep(1)
        XCTAssertFalse(app.buttons["Remove Walking Distance"].exists,
                       "the row should be gone after a single tap")
        attach(app, "3-tile-removed")

        dismissEditor(app)
        sleep(2)
        XCTAssertFalse(app.staticTexts["Walking Distance"].exists,
                       "the removed tile is still in the drawer")
        attach(app, "4-drawer-without-tile")

        // And it comes back.
        openEditor(app)
        let addButton = app.buttons["Add Walking Distance"].firstMatch
        var attempts = 0
        while !addButton.isHittable && attempts < 6 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "a removed tile should be offered under More Tiles")
        addButton.tap()
        sleep(1)
        dismissEditor(app)
        sleep(2)

        XCTAssertTrue(app.staticTexts["Walking Distance"].waitForExistence(timeout: 5),
                      "the re-added tile did not come back")
        attach(app, "5-tile-restored")
    }

    /// The aggregation control is per tile, and only where both readings mean
    /// something — a count of workouts off cadence has no average.
    @MainActor
    func testAggregationControlAppearsOnlyWhereItApplies() throws {
        let app = launch()
        expandDrawer(app)
        openEditor(app)

        XCTAssertTrue(app.buttons["Time in Daylight weekly value"].exists,
                      "daylight should offer average or total")
        XCTAssertFalse(app.buttons["Cadence weekly value"].exists,
                       "cadence has no meaningful average and must not offer one")

        // Daylight defaults to a daily average.
        XCTAssertEqual(app.buttons["Time in Daylight weekly value"].value as? String, "Average")
        attach(app, "1-aggregation-controls")

        // Switching it to Total must change the tile's caption in week scope.
        app.buttons["Time in Daylight weekly value"].tap()
        sleep(1)
        app.buttons["Total"].firstMatch.tap()
        sleep(1)
        dismissEditor(app)
        sleep(2)

        app.buttons["Time period"].tap()
        sleep(1)
        app.buttons["This Week"].firstMatch.tap()
        sleep(2)

        XCTAssertTrue(app.staticTexts["Time in Daylight"].waitForExistence(timeout: 5),
                      "a total should use the plain caption, not 'Daily Avg.'")
        XCTAssertFalse(app.staticTexts["Daily Avg. Daylight"].exists)
        attach(app, "2-week-total")
    }

    // MARK: - Helpers

    /// Each test starts from the default layout; without this, whichever test
    /// ran first would decide what the next one sees.
    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-resetDrawerLayout"]
        app.launch()
        sleep(2)
        return app
    }

    @MainActor
    private func expandDrawer(_ app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93))
            .press(forDuration: 0.05,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        sleep(2)
    }

    @MainActor
    private func openEditor(_ app: XCUIApplication) {
        app.staticTexts["Time in Daylight"].press(forDuration: 0.8)
        sleep(2)
        XCTAssertTrue(app.navigationBars["Customize"].waitForExistence(timeout: 5),
                      "long press did not open the editor")
    }

    /// iOS 26 shows a prominent checkmark; older versions a plain "Done".
    @MainActor
    private func dismissEditor(_ app: XCUIApplication) {
        for label in ["Done", "Close"] {
            let button = app.navigationBars["Customize"].buttons[label]
            if button.exists && button.isHittable {
                button.tap()
                return
            }
        }
        XCTFail("no Done button to dismiss the editor")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
