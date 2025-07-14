//
//  UIApplication.swift
//  Andare
//
//  Created by neg2sode on 2025/5/5.
//

import UIKit

extension UIApplication {
    // Static function to open app-specific settings
    static func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              shared.canOpenURL(settingsUrl) else { return }
        shared.open(settingsUrl)
    }
}
