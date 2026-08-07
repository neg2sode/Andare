//
//  WorkoutSummaryLayoutTests.swift
//  AndareUITests
//
//  Renders the summary over a stand-in ride. A workout recorded on a simulator
//  has neither cadence nor GPS, so the chart and route map — the two sections
//  most worth looking at — are otherwise always empty states.
//

import XCTest

final class WorkoutSummaryLayoutTests: XCTestCase {

    @MainActor
    func testSummarySectionsAppearInOrder() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSampleSummary"]
        app.launch()
        sleep(3)

        // Hero, then route, then chart, then stats.
        let chartTitle = app.staticTexts["Cadence Over Time"]
        let statsTitle = app.staticTexts["Workout Details"]

        XCTAssertTrue(chartTitle.waitForExistence(timeout: 10), "chart section missing")
        XCTAssertTrue(statsTitle.exists, "stats section missing, or still named Workout Summary")
        XCTAssertFalse(app.staticTexts["Workout Summary"].exists,
                       "the stats section should have been renamed")

        // The map keeps its title; only its card background went away.
        let mapTitle = app.staticTexts["Route Map"]
        XCTAssertTrue(mapTitle.exists, "the route map should carry a title")

        // Map above chart above stats.
        XCTAssertLessThan(mapTitle.frame.minY, chartTitle.frame.minY,
                          "Route Map should sit above Cadence Over Time")
        XCTAssertLessThan(chartTitle.frame.minY, statsTitle.frame.minY,
                          "Cadence Over Time should sit above Workout Details")

        attach(app, "1-summary-top")
        app.swipeUp()
        sleep(1)
        attach(app, "2-summary-chart")
        app.swipeUp()
        sleep(1)
        attach(app, "3-summary-stats")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
