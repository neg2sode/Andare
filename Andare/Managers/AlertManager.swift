//
//  AlertManager.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import SwiftUI
import UIKit

final class AlertManager: ObservableObject {
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

