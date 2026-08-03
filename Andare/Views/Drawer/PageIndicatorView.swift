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
    var onSelect: ((Int) -> Void)? = nil

    var body: some View {
        if #available(iOS 26.0, *) {
            dots.glassEffect()
        } else {
            dots
        }
    }

    private var dots: some View {
        HStack(spacing: 0) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Button {
                    onSelect?(index)
                } label: {
                    Circle()
                        // If this circle is the current page, make it larger and opaque.
                        // Otherwise, make it smaller and semi-transparent.
                        .frame(width: 8, height: 8)
                        .foregroundStyle(Color.secondary)
                        .opacity(index == currentPage ? 1.0 : 0.4)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        // Invisible enlarged hit target around the 8pt dot.
                        .frame(width: 44, height: 34)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Page \(index + 1) of \(numberOfPages)")
                .accessibilityAddTraits(index == currentPage ? .isSelected : [])
            }
        }
        // Add a subtle animation when the current page changes.
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: currentPage)
    }
}
