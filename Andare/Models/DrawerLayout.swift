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

    static let `default` = DrawerLayout(
        entries: [.daylight, .steps, .cadence].map { Entry(tile: $0) }
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
        guard let data = try? JSONEncoder().encode(stored),
              let string = String(data: data, encoding: .utf8)
        else { return "[]" }
        return string
    }
}

/// Carries the Phase 8 hide toggles into the layout the first time this version
/// runs, so a card someone deliberately hid does not reappear.
enum DrawerLayoutMigration {
    static let storageKey = "drawerLayout"

    private static let legacyTodayKey = "showTodaySection"
    private static let legacyCadenceKey = "showCadenceSummarySection"

    /// `@AppStorage` alone cannot tell "never set" from "set to empty", which is
    /// why this reads `UserDefaults` directly.
    static func runIfNeeded(_ defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: storageKey) == nil else { return }

        // Absent means the user never turned it off.
        let showToday = defaults.object(forKey: legacyTodayKey) as? Bool ?? true
        let showCadence = defaults.object(forKey: legacyCadenceKey) as? Bool ?? true

        var entries: [DrawerLayout.Entry] = []
        if showToday { entries += [.init(tile: .daylight), .init(tile: .steps)] }
        if showCadence { entries.append(.init(tile: .cadence)) }

        defaults.set(DrawerLayout(entries: entries).rawValue, forKey: storageKey)
        defaults.removeObject(forKey: legacyTodayKey)
        defaults.removeObject(forKey: legacyCadenceKey)
    }
}
