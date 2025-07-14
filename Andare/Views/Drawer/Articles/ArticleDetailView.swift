//
//  ArticleDetailView.swift
//  Andare
//
//  Created by neg2sode on 2025/4/28.
//

import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) var dismiss // Environment value to dismiss the sheet

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Display the thumbnail image at the top if desired
                Image(article.thumbnailImageName)
                     .resizable()
                     .aspectRatio(contentMode: .fit) // Fit within bounds
                     .padding(.bottom)

                // Content based on the article
                articleSpecificContent()
                    .padding(.horizontal) // Add horizontal padding to text content
            }
        }
        .navigationTitle(article.title) // Use article title for navigation bar
        .navigationBarTitleDisplayMode(.inline) // Keep title inline like screenshot
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss() // Call dismiss action
                }
            }
        }
    }

    @ViewBuilder
    private func articleSpecificContent() -> some View {
        // Main container for all sections within the article
        // Use this VStack's spacing to control the gap BETWEEN major sections
        VStack(alignment: .leading, spacing: 30) { // e.g., 25 points between sections

            switch article.title {
            case "Understanding Cycling Cadence":

                // Section 1: What is Cadence?
                VStack(alignment: .leading, spacing: 8) { // Use this spacing for within the section (title <-> body)
                    Text("What is Cadence?")
                        .font(.largeTitle.weight(.bold)) // Make subtitle slightly bolder
                    Text("Cadence is simply your pedaling rate, measured in revolutions per minute (RPM). Think of it like the rhythm or speed of your legs spinning.")
                } // End Section 1

                // Section 2: Why 70-90 RPM?
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why is 70-90 RPM Often Recommended?")
                        .font(.title2.weight(.bold))
                    Text("For casual cycling, this range often represents a sweet spot. It allows for efficient power transfer without putting excessive strain on joints (like knees) or requiring overly rapid, less controlled leg movements.")
                } // End Section 2

                // Section 3: Finding Your Cadence
                VStack(alignment: .leading, spacing: 8) {
                    Text("Finding Your Natural Cadence")
                         .font(.title2.weight(.bold))
                     Text("Everyone is different. Use this app to see your current cadence and experiment with slightly faster or slower rhythms to find what feels comfortable and sustainable for you.")
                } // End Section 3


            case "Knee Pain and Cycling":

                // Section 1: Knee Strain Connection
                 VStack(alignment: .leading, spacing: 8) {
                    Text("The Knee Strain Connection")
                        .font(.largeTitle.weight(.bold))
                    Text("Pushing hard gears at a very low cadence (e.g., below 60 RPM) requires significant force from your leg muscles with each pedal stroke. This force translates to high pressure on your knee joint, particularly the patellofemoral joint (under the kneecap).")
                } // End Section 1

                // Section 2: How Higher Cadence Helps
                VStack(alignment: .leading, spacing: 8) {
                    Text("How Higher Cadence Helps")
                        .font(.title2.weight(.bold))
                    Text("Spinning at a higher cadence (e.g., 70+ RPM) generally means using easier gears. While your legs move faster, the force required for each individual stroke is lower. This reduces the peak stress on your knees, making cycling much gentler on the joints.")
                } // End Section 2

                 // Section 3: Listen to Your Body
                 VStack(alignment: .leading, spacing: 8) {
                    Text("Listen to Your Body")
                         .font(.title2.weight(.bold))
                     Text("While cadence is important, proper bike fit and listening to any pain signals are crucial. If you experience knee pain, consult a professional.")
                } // End Section 3


            default:
                Text("Article content coming soon.")
            }
        }
        // Add padding around the entire block of sections if needed,
        // but the ScrollView in the parent already has .padding(.horizontal)
        // .padding(.vertical) // Add vertical padding if the top/bottom feel too close to edges
    }
}
