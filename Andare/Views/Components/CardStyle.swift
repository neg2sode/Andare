//
//  CardStyle.swift
//  Andare
//
//  Created by neg2sode on 2026/8/1.
//

import SwiftUI

/// Standard card container: secondary grouped background with a rounded clip.
///
/// One radius for every card surface. There used to be a three-tier scale
/// (rows 12, cards 16, containers 20), which meant a grouped row and the card
/// beside it disagreed about their own corners for no reason a user could see.
extension View {
    func cardStyle(radius: CGFloat = 20) -> some View {
        self
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}
