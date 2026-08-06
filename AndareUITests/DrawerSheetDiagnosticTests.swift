//
//  DrawerSheetDiagnosticTests.swift
//  AndareUITests
//
//  Walkthrough for the native drawer sheet: tiny detent on launch,
//  expand to large, collapse back, background interaction intact.
//

import XCTest

final class DrawerSheetDiagnosticTests: XCTestCase {

    @MainActor
    func testDrawerExpandCollapse() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)
        attach(app, "1-launch-tiny-detent")

        // Drag the drawer up to the large detent
        let grabber = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93))
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
        grabber.press(forDuration: 0.05, thenDragTo: top)
        sleep(2)
        attach(app, "2-expanded-large")

        // Collapse back down
        let header = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12))
        let bottom = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        header.press(forDuration: 0.05, thenDragTo: bottom)
        sleep(2)
        attach(app, "3-collapsed-tiny")

        // Background interaction: the start button behind the sheet should react
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.43)).tap()
        sleep(2)
        attach(app, "4-after-background-tap")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
