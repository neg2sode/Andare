//
//  SummaryStatCard.swift
//  Andare
//
//  Created by neg2sode on 2026/8/3.
//

import SwiftUI

/// Individual stat card: caption label above a big rounded value with a tinted unit.
/// Used by the workout summary grid; drawer HealthKit cards adopt it in Phase 6.
struct SummaryStatCard: View {
    let label: String
    let value: String
    let unit: String
    let unitColour: Color
    let icon: String?
    let iconTint: Color

    init(label: String, value: String, unit: String, unitColour: Color, icon: String? = nil, iconTint: Color = .secondary) {
        self.label = label
        self.value = value
        self.unit = unit
        self.unitColour = unitColour
        self.icon = icon
        self.iconTint = iconTint
    }

    init(label: String, stats: FormattedStats, icon: String? = nil, iconTint: Color = .secondary) {
        self.init(label: label, value: stats.value, unit: stats.unit, unitColour: stats.colour, icon: icon, iconTint: iconTint)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(iconTint)
                }

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.body.weight(.medium))
                        .foregroundStyle(unitColour)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value) \(unit)")
    }
}
