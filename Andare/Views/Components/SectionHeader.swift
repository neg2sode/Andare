//
//  SectionHeader.swift
//  Andare
//
//  Created by neg2sode on 2026/8/1.
//

import SwiftUI

/// Muted section title used above grouped cards (Preferences, drawer sections).
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 22)
    }
}
