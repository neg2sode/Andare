//
//  SummaryStatCard.swift
//  Andare
//
//  Created by neg2sode on 2026/8/3.
//

import SwiftUI

/// How much room a stat gets. Drawer tiles are their own small cards and stay
/// compact; the summary screen groups several into one large card and can
/// afford bigger type.
enum SummaryStatSize {
    case compact
    case roomy

    var valueSize: CGFloat {
        switch self {
        case .compact: 28
        case .roomy: 32
        }
    }

    var labelFont: Font {
        switch self {
        case .compact: .caption
        case .roomy: .subheadline
        }
    }
}

/// Caption label above a big rounded value with a tinted unit, without any
/// container of its own — for callers that supply one shared background.
struct SummaryStatContent: View {
    let label: String
    let value: String
    let unit: String
    let unitColour: Color
    var icon: String? = nil
    var iconTint: Color = .secondary
    var size: SummaryStatSize = .compact

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(iconTint)
                }

                Text(label)
                    .font(size.labelFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    // Captions vary in length once a tile can say "Est. Avg.
                    // Daylight"; shrinking beats truncating.
                    .minimumScaleFactor(0.85)
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: size.valueSize, weight: .semibold, design: .rounded))
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value) \(unit)")
    }
}

/// A `SummaryStatContent` in its own card. Used by the drawer's tile grid.
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
        SummaryStatContent(
            label: label,
            value: value,
            unit: unit,
            unitColour: unitColour,
            icon: icon,
            iconTint: iconTint
        )
        .padding()
        .cardStyle()
    }
}
