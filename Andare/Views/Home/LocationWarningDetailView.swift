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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        Text("Why Location Access Matters")
                            .font(.title)
                            .fontWeight(.semibold)

                        // Feature List
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Cadence Monitoring Continuity", systemImage: "gauge")
                                    .font(.body)
                                
                                Text("Ensures your cadence data remains continuous even when the app is running in the background.")
                                    .font(.subheadline)
                                    .padding(.leading, 28)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Label("Real‑Time Alerts", systemImage: "bell.circle")
                                    .font(.body)
                                
                                Text("Get timely notifications for cadence zones.")
                                    .font(.subheadline)
                                    .padding(.leading, 28)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Label("Route Mapping & Stats", systemImage: "map")
                                    .font(.body)
                                
                                Text("Track your distance, speed, and elevation gain on detailed maps.")
                                    .font(.subheadline)
                                    .padding(.leading, 28)
                            }
                        }

                        // Learn More link
                        Link("Learn More", destination: URL(string: "https://google.com")!)
                            .font(.callout)
                            .foregroundStyle(Color.accentColor)

                        Divider()

                        // Privacy Statement
                        Text("Your location data is used solely to power in-app features and is never shared with third parties.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }

                // Fixed action buttons at bottom
                VStack(spacing: 24) {
                    Button {
                        UIApplication.openAppSettings()
                        dismiss()
                    } label: {
                        Text("Enable Tracking in Settings")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        showLocationWarningPreference = false
                        dismiss()
                    } label: {
                        Text("Don't Show Again")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Location Permission")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LocationWarningDetailView_Previews: PreviewProvider {
    static var previews: some View {
        LocationWarningDetailView()
    }
}
