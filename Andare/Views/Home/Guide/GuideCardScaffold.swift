//
//  GuideCardScaffold.swift
//  Andare
//
//  Created by neg2sode on 2026/8/1.
//

import SwiftUI

/// Shared chrome for the guide screens: a scrollable content card on the
/// grouped background with footer buttons pinned outside the scroll area.
struct GuideCardScaffold<Content: View, Footer: View>: View {
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack {
                    Spacer(minLength: 30)

                    content
                        .padding(30)
                        .cardStyle(radius: 20)
                        .frame(maxWidth: 800)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)

                    Spacer(minLength: 30)
                }
                .frame(maxWidth: .infinity)
            }

            footer
                .padding(.horizontal, 30)
                .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
