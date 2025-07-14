//
//  DrawerView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/2.
//

import SwiftUI

struct DrawerView: View {
    @State private var isShowingPreferences = false
    @State private var workoutsExpanded = false
    
    @EnvironmentObject var drawerState: DrawerState

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Drawer Header
            HStack {
                Text("Andare Dev v1.7.1b")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { isShowingPreferences = true }) {
                    Image(systemName: "gearshape.fill")
                        .imageScale(.large)
                        .foregroundStyle(Color.accentColor) // Match the tint
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            .padding(.top, 20)

            // MARK: - Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RecentWorkoutsView(isExpanded: $workoutsExpanded)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Articles")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // The existing ArticlesView now sits below the title
                        ArticlesView()
                    }
                }
            }
            .onChange(of: drawerState.selectedDetent) { _, newDetent in
                guard newDetent != .large else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    workoutsExpanded = false
                }
            }
            
            // MARK: - Footnote
            Text("Made with ☕️ by neg2sode")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $isShowingPreferences) {
            PreferencesView()
                .presentationDetents([.medium])
        }
    }
}
