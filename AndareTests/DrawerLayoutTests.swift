//
//  DrawerLayoutTests.swift
//  AndareTests
//
//  The saved layout is the only record of what a user arranged, so the two
//  things that must not happen are a decode wiping it and a version upgrade
//  resurrecting a card they deliberately hid.
//

import Testing
import Foundation
@testable import Andare

struct DrawerLayoutTests {

    // MARK: - Encoding

    @Test func roundTripsOrderAndAggregation() throws {
        let layout = DrawerLayout(entries: [
            .init(tile: .cadence),
            .init(tile: .steps, aggregation: .average),
            .init(tile: .rideDistance, aggregation: .total)
        ])

        let restored = try #require(DrawerLayout(rawValue: layout.rawValue))
        #expect(restored == layout)
        #expect(restored.entries.map(\.tile) == [.cadence, .steps, .rideDistance])
        #expect(restored.aggregation(for: .steps) == .average)
    }

    /// A nil aggregation must stay nil rather than being baked to the current
    /// default, so a tile whose default changes later follows the change.
    @Test func unsetAggregationStaysUnset() throws {
        let layout = DrawerLayout(entries: [.init(tile: .daylight)])
        let restored = try #require(DrawerLayout(rawValue: layout.rawValue))

        #expect(restored.entries[0].aggregation == nil)
        #expect(restored.aggregation(for: .daylight) == DrawerTile.daylight.defaultAggregation)
    }

    /// The regression this guards: retiring a tile in some future version must
    /// drop that one entry, not reset everything the user arranged.
    @Test func unknownTileIsDroppedNotFatal() throws {
        let raw = #"[{"tile":"steps"},{"tile":"retiredTile"},{"tile":"cadence"}]"#
        let layout = try #require(DrawerLayout(rawValue: raw))

        #expect(layout.entries.map(\.tile) == [.steps, .cadence])
    }

    @Test func malformedRawValueIsRejectedSoTheDefaultApplies() {
        #expect(DrawerLayout(rawValue: "not json") == nil)
    }

    @Test func availableListsOnlyTilesNotAlreadyShown() {
        let layout = DrawerLayout(entries: [.init(tile: .steps), .init(tile: .cadence)])
        #expect(!layout.available.contains(.steps))
        #expect(!layout.available.contains(.cadence))
        #expect(layout.available.contains(.walkingDistance))
    }

    @Test func anEmptyLayoutIsRepresentable() throws {
        let restored = try #require(DrawerLayout(rawValue: DrawerLayout(entries: []).rawValue))
        #expect(restored.entries.isEmpty)
        #expect(restored.available.count == DrawerTile.allCases.count)
    }

    // MARK: - Migration

    private func scratchDefaults(_ name: String = UUID().uuidString) -> UserDefaults {
        UserDefaults(suiteName: name)!
    }

    private func storedLayout(_ defaults: UserDefaults) -> DrawerLayout? {
        DrawerLayout(rawValue: defaults.string(forKey: DrawerLayoutMigration.storageKey) ?? "")
    }

    @Test func aFreshInstallGetsTheWholeCatalog() {
        let defaults = scratchDefaults()
        DrawerLayoutMigration.runIfNeeded(defaults)

        #expect(storedLayout(defaults) == DrawerLayout.default)
        #expect(storedLayout(defaults)?.entries.count == DrawerTile.allCases.count)
    }

    /// Widening the default cannot reach a device that already stored a layout,
    /// so an untouched one is upgraded in place.
    @Test func anUntouchedOldDefaultIsWidened() {
        let defaults = scratchDefaults()
        let oldDefault = DrawerLayout(entries: [.daylight, .steps, .cadence].map { .init(tile: $0) })
        defaults.set(oldDefault.rawValue, forKey: DrawerLayoutMigration.storageKey)
        defaults.set(1, forKey: DrawerLayoutMigration.versionKey)

        DrawerLayoutMigration.runIfNeeded(defaults)

        #expect(storedLayout(defaults) == DrawerLayout.default)
    }

    /// The regression that matters: an arrangement the user actually made is
    /// theirs, even though it is now smaller than the default.
    @Test func aDeliberateArrangementIsNotWidened() {
        let defaults = scratchDefaults()
        let arranged = DrawerLayout(entries: [.init(tile: .cadence), .init(tile: .daylight)])
        defaults.set(arranged.rawValue, forKey: DrawerLayoutMigration.storageKey)
        defaults.set(1, forKey: DrawerLayoutMigration.versionKey)

        DrawerLayoutMigration.runIfNeeded(defaults)

        #expect(storedLayout(defaults) == arranged)
    }

    /// Same three tiles, but the user picked a non-default aggregation — that
    /// is a touched layout too.
    @Test func anOldDefaultWithACustomAggregationIsNotWidened() {
        let defaults = scratchDefaults()
        let tweaked = DrawerLayout(entries: [
            .init(tile: .daylight, aggregation: .total),
            .init(tile: .steps),
            .init(tile: .cadence)
        ])
        defaults.set(tweaked.rawValue, forKey: DrawerLayoutMigration.storageKey)
        defaults.set(1, forKey: DrawerLayoutMigration.versionKey)

        DrawerLayoutMigration.runIfNeeded(defaults)

        #expect(storedLayout(defaults) == tweaked)
    }

    /// Widening happens once. Removing tiles afterwards must stick.
    @Test func wideningDoesNotRepeatOnceStamped() {
        let defaults = scratchDefaults()
        DrawerLayoutMigration.runIfNeeded(defaults)

        let trimmed = DrawerLayout(entries: [.init(tile: .steps)])
        defaults.set(trimmed.rawValue, forKey: DrawerLayoutMigration.storageKey)
        DrawerLayoutMigration.runIfNeeded(defaults)

        #expect(storedLayout(defaults) == trimmed)
    }

    /// Someone who hid the Today card must not have it come back as two tiles.
    @Test func migrationHonoursAHiddenTodayCard() {
        let defaults = scratchDefaults()
        defaults.set(false, forKey: "showTodaySection")

        DrawerLayoutMigration.runIfNeeded(defaults)

        let layout = DrawerLayout(rawValue: defaults.string(forKey: DrawerLayoutMigration.storageKey) ?? "")
        #expect(layout?.entries.map(\.tile) == [.cadence])
    }

    @Test func migrationHonoursBothCardsHidden() {
        let defaults = scratchDefaults()
        defaults.set(false, forKey: "showTodaySection")
        defaults.set(false, forKey: "showCadenceSummarySection")

        DrawerLayoutMigration.runIfNeeded(defaults)

        let layout = DrawerLayout(rawValue: defaults.string(forKey: DrawerLayoutMigration.storageKey) ?? "")
        #expect(layout?.entries.isEmpty == true)
    }

    /// Running again must not overwrite an arrangement made after the upgrade.
    @Test func migrationIsANoOpOnceTheLayoutExists() {
        let defaults = scratchDefaults()
        let arranged = DrawerLayout(entries: [.init(tile: .rideDuration)])
        defaults.set(arranged.rawValue, forKey: DrawerLayoutMigration.storageKey)
        defaults.set(false, forKey: "showTodaySection")

        DrawerLayoutMigration.runIfNeeded(defaults)

        let layout = DrawerLayout(rawValue: defaults.string(forKey: DrawerLayoutMigration.storageKey) ?? "")
        #expect(layout == arranged)
    }

    @Test func migrationClearsTheLegacyKeys() {
        let defaults = scratchDefaults()
        defaults.set(false, forKey: "showTodaySection")

        DrawerLayoutMigration.runIfNeeded(defaults)

        #expect(defaults.object(forKey: "showTodaySection") == nil)
        #expect(defaults.object(forKey: "showCadenceSummarySection") == nil)
    }

    /// An empty layout is a real choice, and must survive a relaunch rather
    /// than being read as "never set" and re-seeded with defaults.
    @Test func anIntentionallyEmptyLayoutSurvivesRelaunch() {
        let defaults = scratchDefaults()
        defaults.set(DrawerLayout(entries: []).rawValue, forKey: DrawerLayoutMigration.storageKey)

        DrawerLayoutMigration.runIfNeeded(defaults)

        let layout = DrawerLayout(rawValue: defaults.string(forKey: DrawerLayoutMigration.storageKey) ?? "")
        #expect(layout?.entries.isEmpty == true)
    }
}
