//
//  ArticleDetailView.swift
//  Andare
//
//  Created by neg2sode on 2025/4/28.
//

import SwiftUI
import Charts

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
        VStack(alignment: .leading, spacing: 25) { // e.g., 25 points between sections
            Text(article.title)
                .font(.largeTitle.weight(.bold))
            
            switch article.title {
            case "Conquering Hills":

                Text("Hills change everything. On an uphill, gravity works against you. On a downhill, momentum takes over. Your natural rhythm gets disrupted either way.")

                // Section 1: Going Up
                VStack(alignment: .leading, spacing: 8) { // Use this spacing for within the section (title <-> body)
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.accentColor)

                        Text("Going Up")
                            .font(.title3.weight(.semibold))
                    }

                    Text("When you hit an uphill, resist the urge to push harder gears or take longer strides. Instead, shift to a lighter gear (cycling) or shorten your stride (running). Keep your cadence steady or even slightly higher than usual.")
                } // End Section 1

                tipBox(
                    icon: "lightbulb.fill",
                    text: "On climbs, aim for quicker and lighter movements rather than powerful ones."
                )

                // Section 2: Going Down
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.right")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.accentColor)

                        Text("Going Down")
                            .font(.title3.weight(.semibold))
                    }

                    Text("Downhills feel easy, but they're deceptively demanding on your joints for running and walking. The impact forces increase, and it's tempting to let your cadence drop as gravity does the work.")
                } // End Section 2

                tipBox(
                    icon: "lightbulb.fill",
                    text: "On descents, quick and controlled steps keep you in control. Or let go of the pedal if you're on a bike."
                )

                // Section 3: The Key Insight
                VStack(alignment: .leading, spacing: 8) {
                    Text("The Key Insight")
                         .font(.title3.weight(.semibold))
                     Text("Whether going up or down, the goal is the same: **keep your rhythm consistent**. Let the terrain change around you while your cadence stays stable.")
                } // End Section 3


            case "The Power of Consistency":

                Text("A single workout won't make or break you. But consistent workouts over years? That's where rhythm habits compound, for better or worse.")

                // Section 1: What Research Suggests
                 VStack(alignment: .leading, spacing: 8) {
                    Text("What Research Suggests")
                        .font(.title3.weight(.semibold))
                    Text("Research on gait and cycling shows that your body naturally settles into an efficient rhythm where energy expenditure is minimized. This freely chosen cadence (FCC) reflects your body's attempt to optimize.")

                    Text("Research also shows that the contribution of different muscle groups changes with cadence. At lower cadences, your ankles do most of the work. At higher cadences, the effort becomes more evenly distributed across hips, knees, and ankles.")
                } // End Section 1

                // Section 2: Why Consistency Matters
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why Consistency Matters")
                        .font(.title3.weight(.semibold))
                    Text("Constantly cycling in hard gears, or alternating between too fast and too slow cadences create uneven stress on your joints. Over months and years, this adds up.")
                } // End Section 2

                tipBox(
                    icon: "repeat",
                    text: "Use Andare to know your natural cadence."
                )


            case "Fatigue & Perceived Effort":

                Text("The same pace feels different depending on how tired you are.")

                // Section 1: What's Actually Happening
                 VStack(alignment: .leading, spacing: 8) {
                    Text("What's Actually Happening")
                        .font(.title3.weight(.semibold))
                    Text("As you exercise, your muscles accumulate fatigue. Your central nervous system also becomes harder to recruit muscle fibers and maintain the same output.")
                } // End Section 1

                // Section 2: The Cadence Connection
                VStack(alignment: .leading, spacing: 8) {
                    Text("The Cadence Connection")
                        .font(.title3.weight(.semibold))
                    Text("When you're fatigued, it's tempting to slow your cadence and push harder with each movement. But this loops back! Slower, harder movements increase stress on fatigued muscles and joints.")
                } // End Section 2

                tipBox(
                    icon: "lightbulb.fill",
                    text: "When fatigue hits, maintain your cadence but reduce your power output. Spin easier gears or take lighter steps."
                )

                 // Section 3: Trust Your Rhythm
                 VStack(alignment: .leading, spacing: 8) {
                    Text("Trust Your Rhythm")
                         .font(.title3.weight(.semibold))
                     Text("By maintaining consistent cadence even when tired, you work with your body's natural efficiency rather than against it.")
                } // End Section 3


            default:
                Text("Article content coming soon.")
            }
        }
        .padding(.bottom, 30)
    }

    // MARK: - Helper Views

    private func tipBox(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.callout)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
