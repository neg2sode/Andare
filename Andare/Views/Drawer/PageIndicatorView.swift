//
//  PageIndicatorView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/20.
//

import SwiftUI

struct PageIndicatorView: View {
    let numberOfPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    // If this circle is the current page, make it larger and opaque.
                    // Otherwise, make it smaller and semi-transparent.
                    .frame(width: 8, height: 8)
                    .foregroundStyle(Color.secondary)
                    .opacity(index == currentPage ? 1.0 : 0.4)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
            }
        }
        // Add a subtle animation when the current page changes.
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: currentPage)
    }
}
