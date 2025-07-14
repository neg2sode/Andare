//
//  Article.swift
//  Andare
//
//  Created by neg2sode on 2025/4/28.
//

import SwiftUI // Needed for Identifiable

struct Article: Identifiable {
    let id = UUID() // Conformance to Identifiable for ForEach
    let title: String
    let subtitle: String
    let thumbnailImageName: String // Name of the image in Assets.xcassets
    // We'll define the detailed content view separately
}
