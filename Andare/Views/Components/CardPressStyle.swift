//
//  CardPressStyle.swift
//  Andare
//
//  Created by neg2sode on 2026/8/3.
//

import SwiftUI

/// Subtle press-scale feedback for tappable cards.
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
