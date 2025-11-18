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
                if #available(iOS 26.0, *) {
                    Button(role: .close) {
                        dismiss() // Call dismiss action
                    }
                } else {
                    Button("Done") {
                        dismiss() // Call dismiss action
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func articleSpecificContent() -> some View {
        // Main container for all sections within the article
        // Use this VStack's spacing to control the gap BETWEEN major sections
        VStack(alignment: .leading, spacing: 25) { // e.g., 25 points between sections
            Text(article.title)
                .font(.largeTitle.weight(.bold))
            
            switch article.title {
            case "Understanding Cadence":

                // Section 1: What is Cadence?
                VStack(alignment: .leading, spacing: 8) { // Use this spacing for within the section (title <-> body)
                    Text("What is Cadence?")
                        .font(.title2.weight(.bold)) // Make subtitle slightly bolder
                    Text("Cadence is the rhythm of your movement, measured in steps (SPM) or revolutions (RPM) per minute. It's the tempo of your workout.")
                } // End Section 1
                
                // TODO: Placeholder for the "Efficiency Curve" chart
                // We can add a custom, hardcoded chart view here later.
                // EfficiencyCurveChartView()

                // Section 2: Why 70-90 RPM?
                VStack(alignment: .leading, spacing: 8) {
                    Text("The Efficiency Sweet Spot")
                        .font(.title2.weight(.bold))
                    Text("For any given speed, there's an optimal cadence that minimizes oxygen consumption and muscular fatigue. This 'sweet spot' is different for everyone and for each activity.")
                } // End Section 2

                // Section 3: Finding Your Cadence
                VStack(alignment: .leading, spacing: 8) {
                    Text("Finding Your Natural Cadence")
                         .font(.title2.weight(.bold))
                     Text("Everyone is different. Use this app to see your current cadence and experiment with slightly faster or slower rhythms to find what feels comfortable and sustainable for you.")
                } // End Section 3


            case "Cadence and Joint Health":

                // Section 1: Knee Strain Connection
                 VStack(alignment: .leading, spacing: 8) {
                    Text("The Knee Strain Connection")
                        .font(.title2.weight(.bold))
                    Text("Every step or pedal stroke places a force on your joints, especially your knees and ankles. Pushing hard gears at a very low cadence (below 60 RPM) requires significant force from your leg muscles with each pedal stroke. This force translates to high pressure on your knee joint.")
                } // End Section 1
                
                // TODO: Placeholder for the "Joint Stress vs. Cadence" chart
                // JointStressChartView()

                // Section 2: How Higher Cadence Helps
                VStack(alignment: .leading, spacing: 8) {
                    Text("The Benefit of a Quicker Tempo")
                        .font(.title2.weight(.bold))
                    Text("By increasing your cadence slightly, you reduce the force of each individual movement, which can significantly lower the overall stress on your knees and hips over the course of a workout.")
                } // End Section 2

                 // Section 3: Listen to Your Body
                 VStack(alignment: .leading, spacing: 8) {
                    Text("Listen to Your Body")
                         .font(.title2.weight(.bold))
                     Text("While cadence is important, proper form and listening to any pain signals are crucial. If you experience persistent joint pain, it's always best to consult a professional.")
                } // End Section 3


            default:
                Text("Article content coming soon.")
            }
        }
        .padding(.bottom, 30)
    }
}
