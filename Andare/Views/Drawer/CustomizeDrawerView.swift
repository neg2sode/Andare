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
    @AppStorage(DrawerLayoutMigration.storageKey) private var layout = DrawerLayout.default
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Included") {
                    ForEach(layout.entries) { entry in
                        row(for: entry)
                    }
                    .onMove(perform: move)
                    .onDelete(perform: remove)

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
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close) { dismiss() }
                    } else {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func row(for entry: DrawerLayout.Entry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(entry.tile.editorTitle)
            } icon: {
                Image(systemName: entry.tile.icon)
                    .foregroundStyle(entry.tile.iconTint)
            }

            // A count of workouts off cadence has no average, so the control
            // only appears where both readings mean something.
            if entry.tile.supportsAggregation {
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
        }
    }

    // MARK: - Mutation

    private func move(from source: IndexSet, to destination: Int) {
        layout.entries.move(fromOffsets: source, toOffset: destination)
    }

    private func remove(at offsets: IndexSet) {
        layout.entries.remove(atOffsets: offsets)
    }

    private func add(_ tile: DrawerTile) {
        withAnimation {
            layout.entries.append(.init(tile: tile))
        }
    }

    private func setAggregation(_ aggregation: Aggregation, for tile: DrawerTile) {
        guard let index = layout.entries.firstIndex(where: { $0.tile == tile }) else { return }
        layout.entries[index].aggregation = aggregation
    }
}
