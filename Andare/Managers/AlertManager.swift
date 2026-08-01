//
//  AlertManager.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import SwiftUI
import UIKit

/// Usage pattern: one `.alert` host per *presentation context*, because SwiftUI
/// alerts must attach to the topmost presented view.
/// - Main context (home + drawer): use `AlertManager.shared`; the single host
///   lives in `DrawerView` (the drawer sheet is always presented).
/// - Independently presented sheets (e.g. Preferences): own `AlertManager()`
///   instance with its own `.alert` host inside that sheet.
final class AlertManager: ObservableObject {
    static let shared = AlertManager()
    
    @Published var isPresenting: Bool = false
    @Published var title: String = ""
    @Published var message: String = ""
    @Published var showSettingsButton: Bool = false
    
    func reset() {
        self.isPresenting = false
        self.title = ""
        self.message = ""
        self.showSettingsButton = false
    }
    
    func showAlert(title: String, message: String, showSettingsButton: Bool = false) {
        self.title = title
        self.message = message
        self.showSettingsButton = showSettingsButton
        self.isPresenting = true
    }
}

