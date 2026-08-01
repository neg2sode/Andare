//
//  DrawerState.swift
//  Andare
//
//  Created by neg2sode on 2025/7/9.
//

import SwiftUI

// A simple ObservableObject to hold the state of our custom drawer sheet.
final class DrawerState: ObservableObject {
    @Published var selectedDetent: UISheetPresentationController.Detent.Identifier?
}
