//
//  DrawerLayout.swift
//  Andare
//
//  Created by neg2sode on 2026/8/7.
//

import Foundation

/// Which tiles the drawer shows, in what order, and how each condenses a week.
///
/// Order and aggregation live in one value rather than two `UserDefaults` keys
/// so they cannot desync — separate keys leave room for an aggregation entry
/// naming a tile that is no longer included.
///
/// `@AppStorage` accepts any `RawRepresentable` whose `RawValue` is `String`, so
/// this stores as JSON: a real Swift type at the call site, an atomic write, and
/// something still legible in the plist when debugging.
struct DrawerLayout: RawRepresentable, Codable, Equatable {

    struct Entry: Codable, Equatable, Identifiable {
        var tile: DrawerTile
        /// nil means "whatever the tile's default is", so a tile whose default
        /// changes in a future version follows it rather than being pinned.
        var aggregation: Aggregation?

        var id: DrawerTile { tile }

        init(tile: DrawerTile, aggregation: Aggregation? = nil) {
            self.tile = tile
            self.aggregation = aggregation
        }

        var resolvedAggregation: Aggregation {
            aggregation ?? tile.defaultAggregation
        }
    }

    var entries: [Entry]

    /// Declared explicitly because it must not be inferred.
    ///
    /// A type that is both `RawRepresentable` and `Equatable` picks up the
    /// standard library's generic `==`, which compares `rawValue` — here, a
    /// JSON string. `JSONEncoder` gives no key-order guarantee, so two
    /// identical layouts could compare unequal purely on serialisation order,
    /// and `@AppStorage` would see phantom changes.
    static func == (lhs: DrawerLayout, rhs: DrawerLayout) -> Bool {
        lhs.entries == rhs.entries
    }

    /// Everything the app can show. `.cadence` is last because it is the one
    /// wide tile, and a wide tile in the middle breaks up a pair of narrow ones.
    static let `default` = DrawerLayout(
        entries: [.daylight, .steps, .walkingDistance, .rideDistance, .rideDuration, .cadence]
            .map { Entry(tile: $0) }
    )

    init(entries: [Entry]) {
        self.entries = entries
    }

    /// Tiles not currently on the drawer, in catalog order — the "More Tiles"
    /// list in the editor.
    var available: [DrawerTile] {
        let included = Set(entries.map(\.tile))
        return DrawerTile.allCases.filter { !included.contains($0) }
    }

    func aggregation(for tile: DrawerTile) -> Aggregation {
        entries.first { $0.tile == tile }?.resolvedAggregation ?? tile.defaultAggregation
    }

    // MARK: - RawRepresentable

    /// Decoded through a stringly-typed intermediate so an unrecognised tile
    /// identifier drops that one entry instead of failing the whole decode.
    /// A strict decode would reset a user's whole layout the first time we
    /// retire a tile.
    private struct StoredEntry: Codable {
        var tile: String
        var aggregation: String?
    }

    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let stored = try? JSONDecoder().decode([StoredEntry].self, from: data)
        else { return nil }

        self.entries = stored.compactMap { entry in
            guard let tile = DrawerTile(rawValue: entry.tile) else { return nil }
            return Entry(tile: tile, aggregation: entry.aggregation.flatMap(Aggregation.init(rawValue:)))
        }
    }

    var rawValue: String {
        let stored = entries.map {
            StoredEntry(tile: $0.tile.rawValue, aggregation: $0.aggregation?.rawValue)
        }
        let encoder = JSONEncoder()
        // Stable key order, so re-saving an unchanged layout produces a byte
        // identical string rather than a gratuitous UserDefaults write.
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(stored),
              let string = String(data: data, encoding: .utf8)
        else { return "[]" }
        return string
    }
}

/// Carries the Phase 8 hide toggles into the layout the first time this version
/// runs, so a card someone deliberately hid does not reappear.
enum DrawerLayoutMigration {
    static let storageKey = "drawerLayout"
    static let versionKey = "drawerLayoutVersion"

    /// 1 = seeded from the Phase 8 hide toggles.
    /// 2 = default widened from three tiles to the whole catalog.
    static let currentVersion = 2

    private static let legacyTodayKey = "showTodaySection"
    private static let legacyCadenceKey = "showCadenceSummarySection"

    /// The three tiles that used to be the default, in their original order.
    private static let firstDefault: [DrawerTile] = [.daylight, .steps, .cadence]

    /// `@AppStorage` alone cannot tell "never set" from "set to empty", which is
    /// why this reads `UserDefaults` directly.
    static func runIfNeeded(_ defaults: UserDefaults = .standard) {
        seedFromLegacyTogglesIfNeeded(defaults)
        widenDefaultIfUntouched(defaults)
        defaults.set(currentVersion, forKey: versionKey)
    }

    private static func seedFromLegacyTogglesIfNeeded(_ defaults: UserDefaults) {
        guard defaults.object(forKey: storageKey) == nil else { return }

        let showToday = defaults.object(forKey: legacyTodayKey) as? Bool
        let showCadence = defaults.object(forKey: legacyCadenceKey) as? Bool

        // Neither toggle present means a fresh install rather than an upgrade,
        // so there is nothing to carry over.
        guard showToday != nil || showCadence != nil else {
            defaults.set(DrawerLayout.default.rawValue, forKey: storageKey)
            return
        }

        // Absent means the user never turned that one off.
        var entries: [DrawerLayout.Entry] = []
        if showToday ?? true { entries += [.init(tile: .daylight), .init(tile: .steps)] }
        if showCadence ?? true { entries.append(.init(tile: .cadence)) }

        defaults.set(DrawerLayout(entries: entries).rawValue, forKey: storageKey)
        defaults.removeObject(forKey: legacyTodayKey)
        defaults.removeObject(forKey: legacyCadenceKey)
    }

    /// Widening the default cannot reach a device that already stored a layout,
    /// so upgrade one that is still untouched. An arrangement the user actually
    /// made is theirs — leave it alone even though it is now smaller than the
    /// default, because we cannot tell "never bothered" from "deliberate".
    private static func widenDefaultIfUntouched(_ defaults: UserDefaults) {
        guard defaults.integer(forKey: versionKey) < 2,
              let raw = defaults.string(forKey: storageKey),
              let stored = DrawerLayout(rawValue: raw),
              stored.entries.map(\.tile) == firstDefault,
              stored.entries.allSatisfy({ $0.aggregation == nil })
        else { return }

        defaults.set(DrawerLayout.default.rawValue, forKey: storageKey)
    }
}
