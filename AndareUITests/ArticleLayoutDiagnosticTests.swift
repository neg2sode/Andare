//
//  ArticleLayoutDiagnosticTests.swift
//  AndareUITests
//
//  Guards against article content that is wider than the screen, which turns
//  the vertical article ScrollView into a two-axis one: the page drifts
//  sideways and rubber-bands back, showing blank gutters. This happened when a
//  fitted full-bleed image rounded up to 414.5pt on a 414pt screen.
//

import XCTest

final class ArticleLayoutDiagnosticTests: XCTestCase {

    private var report = ""

    @MainActor
    func testArticleContentIsNeverWiderThanTheScreen() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        let screenWidth = app.frame.width
        report += "SCREEN WIDTH: \(screenWidth)\n"

        // Expand the drawer to reach the article list.
        let grabber = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93))
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
        grabber.press(forDuration: 0.05, thenDragTo: top)
        sleep(2)

        for title in ["Conquering Hills", "The Power of Consistency", "Fatigue & Perceived Effort"] {
            let card = app.staticTexts[title]
            var attempts = 0
            while !card.isHittable && attempts < 12 {
                app.swipeUp()
                attempts += 1
            }
            XCTAssertTrue(card.waitForExistence(timeout: 5), "article card '\(title)' not reachable")
            card.tap()
            sleep(3)

            report += "\n=== ARTICLE: \(title)\n"
            // Images and text are the content that can overrun the container:
            // an image via aspect-ratio rounding, text via an unbreakable word.
            for type in [XCUIElement.ElementType.image, .staticText] {
                let query = app.descendants(matching: type)
                for i in 0..<query.count {
                    let el = query.element(boundBy: i)
                    guard el.exists else { continue }
                    let frame = el.frame
                    guard frame.width > 0 else { continue }
                    let name = el.identifier.isEmpty ? String(el.label.prefix(40)) : el.identifier
                    let tooWide = frame.width > screenWidth + 0.01
                    if tooWide {
                        report += String(format: "OVERFLOW w=%.2f %@\n", frame.width, name)
                    }
                    XCTAssertLessThanOrEqual(
                        frame.width, screenWidth + 0.01,
                        "'\(name)' in '\(title)' is \(frame.width)pt wide on a \(screenWidth)pt screen"
                    )
                }
            }

            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "article-\(title)"
            shot.lifetime = .keepAlways
            add(shot)

            app.buttons["Done"].tap()
            sleep(2)
        }

        let dump = XCTAttachment(string: report)
        dump.name = "overflow-report"
        dump.lifetime = .keepAlways
        add(dump)
    }
}
