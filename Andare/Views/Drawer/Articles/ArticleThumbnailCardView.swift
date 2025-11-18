//
//  ArticleThumbnailCardView.swift
//  Andare
//
//  Created by neg2sode on 2025/4/28.
//

import SwiftUI

struct ArticleThumbnailCardView: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 5) { // Use spacing: 0 to let content define gaps
            Image(article.thumbnailImageName)
                .resizable()
                .aspectRatio(contentMode: .fill) // Fill the frame
                // Define a fixed height or aspect ratio for the image area
                .frame(height: 200)
                .clipped() // Prevent image from spilling out

            VStack(alignment: .leading, spacing: 5) {
                Text(article.title)
                    .font(.title2.weight(.bold))
                    .padding(.top, 8) // Add padding above title

                Text(article.subtitle)
                    .font(.body)
                    .padding(.top, 2) // Small padding between title and subtitle
            }
            .padding([.leading, .trailing, .bottom]) // Padding for text content
        }
        // Styling for the card itself
        .background(Color(.secondarySystemGroupedBackground)) // Subtle background color
        .cornerRadius(20)
        .shadow(radius: 3, x: 0, y: 2) // Optional shadow
        .padding(.vertical, 8) // Space between cards
    }
}
