//
//  PrimaryButtonStyle.swift
//  Andare
//
//  Created by neg2sode on 2026/8/1.
//

import SwiftUI

/// Filled accent-colour action button used in guide footers and floating
/// "Done" buttons. Radius 16 for inline placement; footers may use larger.
struct PrimaryButtonStyle: ButtonStyle {
    var radius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline).fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}
