//
//  ArticlesView.swift
//  Andare
//
//  Created by neg2sode on 2025/4/27.
//

import SwiftUI

struct ArticlesView: View {
    let articles: [Article] = [
        Article(title: "Understanding Cycling Cadence",
                subtitle: "Why finding the right rhythm matters.",
                thumbnailImageName: "thumbnail_cadence"), // Make sure this image exists in Assets
        Article(title: "Knee Pain and Cycling",
                subtitle: "How cadence impacts your knee health.",
                thumbnailImageName: "thumbnail_knee_pain"), // Make sure this image exists in Assets
        // Add more articles here later
    ]
    
    // State variable to track the selected article for the sheet
    @State private var selectedArticle: Article? = nil

    var body: some View {
        VStack(spacing: 10) {
            ForEach(articles) { article in
                ArticleThumbnailCardView(article: article)
                    .onTapGesture {
                        self.selectedArticle = article // Set the selected article on tap
                    }
            }
        }
        .padding() // Padding around the entire list
        .sheet(item: $selectedArticle) { article in
            // The content of the sheet
            // Wrap ArticleDetailView in NavigationView to get the title bar and Done button
            NavigationView {
                ArticleDetailView(article: article)
            }
        }
    }
}

struct ArticlesView_Previews: PreviewProvider {
    static var previews: some View {
        ArticlesView()
    }
}
