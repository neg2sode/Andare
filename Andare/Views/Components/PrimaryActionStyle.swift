//
//  PrimaryActionStyle.swift
//  Andare
//
//  Created by neg2sode on 2026/8/7.
//

import SwiftUI

extension View {
    /// Styling for a screen's single major action — guide footers, the summary
    /// sheet's Done button, the location warning.
    ///
    /// iOS 26 gets Liquid Glass; everything below falls back to the filled
    /// accent button. Both are pinned to a 20pt corner radius so the control
    /// keeps the same silhouette across versions.
    ///
    /// The button's own label supplies `.frame(maxWidth: .infinity)`, since
    /// the glass style has no opinion about width.
    @ViewBuilder
    func primaryActionStyle(tint: Color = .accentColor) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
                .tint(tint)
                .controlSize(.extraLarge)
                .buttonBorderShape(.roundedRectangle(radius: 20))
        } else {
            self.buttonStyle(PrimaryButtonStyle(tint: tint))
        }
    }
}
