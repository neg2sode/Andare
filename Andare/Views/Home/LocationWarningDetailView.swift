//
//  LocationWarningDetailView.swift
//  Andare
//
//  Created by neg2sode on 2025/5/4.
//

import SwiftUI

struct LocationWarningDetailView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("showLocationWarningPreference") private var showLocationWarningPreference = true
    @State private var bounceMetronome = false
    @State private var bounceBell = false
    @State private var bounceMap = false

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text("Why Location Permission Matters")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                    // Feature List
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Cadence Monitoring Continuity", systemImage: "metronome")
                                .font(.body)
                                .symbolEffect(.bounce.byLayer, options: .speed(2.56), value: bounceMetronome)
                            
                            Text("Ensures your cadence data remains continuous even when the app is running in the background.")
                                .font(.subheadline)
                                .padding(.leading, 28)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Real‑Time Alerts", systemImage: "bell")
                                .font(.body)
                                .symbolEffect(.bounce.byLayer, options: .speed(2.56), value: bounceBell)
                            
                            Text("Get timely notifications for cadence zones.")
                                .font(.subheadline)
                                .padding(.leading, 28)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Route Mapping & Stats", systemImage: "map")
                                .font(.body)
                                .symbolEffect(.bounce.byLayer, options: .speed(2.56), value: bounceMap)
                            
                            Text("Track your distance, speed, and elevation gain on detailed maps.")
                                .font(.subheadline)
                                .padding(.leading, 28)
                        }
                    }
                    
                    Text("Critical for all features.")
                        .font(.callout)
                        .fontWeight(.bold)

                    // Learn More link
                    Link("Learn More", destination: URL(string: "https://github.com/neg2sode/Andare")!)
                        .font(.callout)
                        .foregroundStyle(Color.accentColor)

                    Divider()

                    // Privacy Statement
                    Text("Your location data is used solely to power in-app features and is never shared with third parties.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical)
                .padding(.horizontal, 22)
            }

            // Fixed action buttons at bottom
            VStack(spacing: 24) {
                if #available(iOS 26.0, *) {
                    Button {
                        UIApplication.openAppSettings()
                        dismiss()
                    } label: {
                        Text("Enable in Settings")
                            .font(.headline).fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                } else {
                    Button {
                        UIApplication.openAppSettings()
                        dismiss()
                    } label: {
                        Text("Enable in Settings")
                            .font(.headline).fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .shadow(radius: 5)
                    .controlSize(.large)
                }

                Button {
                    showLocationWarningPreference = false
                    dismiss()
                } label: {
                    Text("Don't Show Again")
                        .font(.headline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            }
            .padding(.horizontal, 30)
            .padding(.bottom)
            .background(Color(.systemBackground))
        }
        .task {
            // Sequential bounce animation with pause between cycles
            while !Task.isCancelled {
                // Bounce metronome
                bounceMetronome.toggle()
                try? await Task.sleep(for: .seconds(0.5))
                
                // Bounce bell
                bounceBell.toggle()
                try? await Task.sleep(for: .seconds(0.5))
                
                // Bounce map
                bounceMap.toggle()
                try? await Task.sleep(for: .seconds(0.5))
                
                // Pause before next cycle
                try? await Task.sleep(for: .seconds(1.5))
            }
        }
    }
}

struct LocationWarningDetailView_Previews: PreviewProvider {
    static var previews: some View {
        LocationWarningDetailView()
    }
}
