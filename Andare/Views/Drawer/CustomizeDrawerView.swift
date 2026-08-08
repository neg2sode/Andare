//
//  CustomizeDrawerView.swift
//  Andare
//
//  Created by neg2sode on 2026/8/7.
//

import SwiftUI

/// Reorder, add and remove the drawer's tiles, and choose how each condenses a
/// week.
///
/// This is a sheet rather than drag-to-reorder in the drawer itself: the drawer
/// is a `ScrollView` inside a sheet with detents, so an in-place drag would be
/// competing with the sheet's own drag gesture. A `List` in edit mode gets the
/// grab handles for free and cannot fight anything.
struct CustomizeDrawerView: View {
    @AppStorage(DrawerLayout.storageKey) private var layout = DrawerLayout.default
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Included") {
                    ForEach(layout.entries) { entry in
                        row(for: entry)
                    }
                    .onMove(perform: move)
                    // Removal is a one-tap ⊖ in the row instead. Both the swipe
                    // and edit mode's own minus need a second confirming tap,
                    // which is friction for something a single tap restores.
                    .deleteDisabled(true)

                    if layout.entries.isEmpty {
                        Text("No tiles. Add one below.")
                            .foregroundStyle(.secondary)
                    }
                }

                if !layout.available.isEmpty {
                    Section("More Tiles") {
                        ForEach(layout.available) { tile in
                            Button {
                                add(tile)
                            } label: {
                                Label {
                                    Text(tile.editorTitle).foregroundStyle(.primary)
                                } icon: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .accessibilityLabel("Add \(tile.editorTitle)")
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // A tick, not an ✕: leaving this sheet confirms an arrangement
                // rather than abandoning one. Matches the Preferences header.
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26.0, *) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .buttonStyle(.glassProminent)
                        .accessibilityLabel("Done")
                    } else {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func row(for entry: DrawerLayout.Entry) -> some View {
        HStack(spacing: 12) {
            Button {
                remove(entry.tile)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            // A List row would otherwise treat a tap anywhere as this button.
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(entry.tile.editorTitle)")

            // Title and its aggregation share a column, so the second line
            // reads as belonging to the tile rather than to the remove button.
            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text(entry.tile.editorTitle)
                } icon: {
                    Image(systemName: entry.tile.icon)
                        .foregroundStyle(entry.tile.iconTint)
                }

                // A count of workouts off cadence has no average, so the
                // control only appears where both readings mean something.
                if entry.tile.supportsAggregation {
                    aggregationControl(for: entry)
                }
            }
        }
    }

    private func aggregationControl(for entry: DrawerLayout.Entry) -> some View {
        HStack {
            Text("This week")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Menu {
                ForEach(Aggregation.allCases) { option in
                    Button {
                        setAggregation(option, for: entry.tile)
                    } label: {
                        HStack {
                            Text(option.label)
                            if entry.resolvedAggregation == option {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(entry.resolvedAggregation.label)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                }
                .font(.caption)
            }
            .accessibilityLabel("\(entry.tile.editorTitle) weekly value")
            .accessibilityValue(entry.resolvedAggregation.label)
        }
    }

    // MARK: - Mutation

    /// The same spring the workout list animates with, so the two feel related.
    private static let shuffle = Animation.spring(response: 0.35, dampingFraction: 0.8)

    private func move(from source: IndexSet, to destination: Int) {
        withAnimation(Self.shuffle) {
            layout.entries.move(fromOffsets: source, toOffset: destination)
        }
    }

    private func remove(_ tile: DrawerTile) {
        withAnimation(Self.shuffle) {
            layout.entries.removeAll { $0.tile == tile }
        }
    }

    private func add(_ tile: DrawerTile) {
        withAnimation(Self.shuffle) {
            layout.entries.append(.init(tile: tile))
        }
    }

    private func setAggregation(_ aggregation: Aggregation, for tile: DrawerTile) {
        guard let index = layout.entries.firstIndex(where: { $0.tile == tile }) else { return }
        layout.entries[index].aggregation = aggregation
    }
}
