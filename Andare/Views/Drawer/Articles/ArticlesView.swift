//
//  ArticlesView.swift
//  Andare
//
//  Created by neg2sode on 2025/4/27.
//

import SwiftUI

struct ArticlesView: View {
    let articles: [Article] = [
        Article(title: "Understanding Cadence",
                subtitle: "Why finding the right rhythm matters.",
                thumbnailImageName: "thumbnail_cadence"), // Make sure this image exists in Assets
        Article(title: "Cadence and Joint Health",
                subtitle: "How cadence impacts your knee health.",
                thumbnailImageName: "thumbnail_knee_pain"), // Make sure this image exists in Assets
        // Add more articles here later
    ]
    
    // State variable to track the selected article for the sheet
    @State private var selectedArticle: Article? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Articles")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(articles) { article in
                    ArticleThumbnailCardView(article: article)
                        .onTapGesture {
                            self.selectedArticle = article // Set the selected article on tap
                        }
                }
            }
            .padding(.horizontal)
            .sheet(item: $selectedArticle) { article in
                // The content of the sheet
                // Wrap ArticleDetailView in NavigationView to get the title bar and Done button
                NavigationView {
                    ArticleDetailView(article: article)
                }
            }
        }
    }
}

struct ArticlesView_Previews: PreviewProvider {
    static var previews: some View {
        ArticlesView()
    }
}
