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
    func testLongPressOpensEditorAndAddingATileShowsItInTheDrawer() throws {
        let app = XCUIApplication()
        // Each test starts from the default layout; without this, whichever
        // test ran first would decide what the next one sees.
        app.launchArguments = ["-resetDrawerLayout"]
        app.launch()
        sleep(2)
        expandDrawer(app)

        XCTAssertTrue(app.staticTexts["Time in Daylight"].waitForExistence(timeout: 5),
                      "default layout should include the daylight tile")
        XCTAssertFalse(app.staticTexts["Walking Distance"].exists,
                       "walking distance is not in the default layout")
        attach(app, "1-default-layout")

        app.staticTexts["Time in Daylight"].press(forDuration: 0.8)
        sleep(2)

        XCTAssertTrue(app.navigationBars["Customize"].waitForExistence(timeout: 5),
                      "long press did not open the editor")
        attach(app, "2-editor")

        app.buttons["Add Walking Distance"].firstMatch.tap()
        sleep(1)
        attach(app, "3-tile-added")

        dismissEditor(app)
        sleep(2)

        XCTAssertTrue(app.staticTexts["Walking Distance"].waitForExistence(timeout: 5),
                      "the added tile did not appear in the drawer")
        attach(app, "4-drawer-with-new-tile")
    }

    /// The aggregation control is per tile, and only where both readings mean
    /// something — a count of workouts off cadence has no average.
    @MainActor
    func testAggregationControlAppearsOnlyWhereItApplies() throws {
        let app = XCUIApplication()
        // Each test starts from the default layout; without this, whichever
        // test ran first would decide what the next one sees.
        app.launchArguments = ["-resetDrawerLayout"]
        app.launch()
        sleep(2)
        expandDrawer(app)

        app.staticTexts["Time in Daylight"].press(forDuration: 0.8)
        sleep(2)
        XCTAssertTrue(app.navigationBars["Customize"].waitForExistence(timeout: 5))

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

    @MainActor
    private func expandDrawer(_ app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93))
            .press(forDuration: 0.05,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        sleep(2)
    }

    /// iOS 26 labels the role-based close button "Close"; older versions "Done".
    @MainActor
    private func dismissEditor(_ app: XCUIApplication) {
        for label in ["Close", "Done"] {
            let button = app.navigationBars["Customize"].buttons[label]
            if button.exists && button.isHittable {
                button.tap()
                return
            }
        }
        XCTFail("no Close or Done button to dismiss the editor")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
