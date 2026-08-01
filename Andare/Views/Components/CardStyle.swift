//
//  CardStyle.swift
//  Andare
//
//  Created by neg2sode on 2026/8/1.
//

import SwiftUI

/// Standard card container: secondary grouped background with a rounded clip.
/// Radius scale: rows/groups 12, cards 16, large containers 20.
extension View {
    func cardStyle(radius: CGFloat = 16) -> some View {
        self
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}
