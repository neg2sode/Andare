//
//  PermissionRow.swift
//  Andare
//
//  Created by neg2sode on 2026/8/1.
//

import SwiftUI

/// One row describing a permission and its state. Two usages:
/// - Plain row (Preferences): title + trailing status icon; row-level tap is
///   handled by the caller wrapping it in a Button.
/// - Guide row: adds an icon tile and subtitle, and shows a "Grant" button
///   (via `grantAction`) while the permission is undetermined.
struct PermissionRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var iconTint: Color = .green
    let status: PermissionStatus
    var grantAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 16) {
            if let icon {
                Image(systemName: icon)
                    .font(.title2).foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(iconTint.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading) {
                Text(title)
                    .font(subtitle == nil ? .body : .headline)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let grantAction, status == .notDetermined {
                Button("Grant", action: grantAction)
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
            } else {
                Image(systemName: status.iconName)
                    .font(subtitle == nil ? .body : .title2)
                    .foregroundStyle(status.iconColour)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        // The status is colour and glyph only, so spell it out for VoiceOver.
        .accessibilityElement(children: status == .notDetermined && grantAction != nil ? .contain : .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts = [title]
        if let subtitle { parts.append(subtitle) }
        parts.append(status.accessibilityDescription)
        return parts.joined(separator: ", ")
    }
}
