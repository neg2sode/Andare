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
        guard let url = URL(string: UIApplication.openSettingsURLString),
              shared.canOpenURL(url) else { return }
        shared.open(url)
    }
    
    static func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        shared.open(url)
    }
}
