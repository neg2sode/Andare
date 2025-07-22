//
//  FullMapView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/1.
//

import SwiftUI
import MapKit

struct FullMapView: View {
    let initialMapCameraPosition: MapCameraPosition
    let routePolyline: MKPolyline
    let start: CLLocationCoordinate2D
    let end: CLLocationCoordinate2D
    let formattedTitle: String
    
    @State private var localMapCameraPosition: MapCameraPosition
    @Environment(\.dismiss) var dismiss
    
    init(initialMapCameraPosition: MapCameraPosition, routePolyline: MKPolyline, start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, formattedTitle: String) {
        self.initialMapCameraPosition = initialMapCameraPosition
        self._localMapCameraPosition = State(initialValue: initialMapCameraPosition)
        self.routePolyline = routePolyline
        self.start = start
        self.end = end
        self.formattedTitle = formattedTitle
    }
    
    var body: some View {
        NavigationView {
            Map(position: $localMapCameraPosition, interactionModes: .all) {
                WorkoutSummaryView.routeMapContent(polyline: routePolyline, start: start, end: end)
            }
            .mapControlVisibility(.automatic)
            .navigationTitle(formattedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss() // Call dismiss action
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}
