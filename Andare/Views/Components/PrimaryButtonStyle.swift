//
//  PrimaryButtonStyle.swift
//  Andare
//
//  Created by neg2sode on 2026/8/1.
//

import SwiftUI

/// Filled accent-colour action button used for every major action: guide
/// footers, the summary sheet's Done button, and the location warning.
/// One radius across all of them so major actions read as a single control.
struct PrimaryButtonStyle: ButtonStyle {
    var radius: CGFloat = 20
    var tint: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline).fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}
