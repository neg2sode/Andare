//
//  MailUtilities.swift
//  Andare
//
//  Created by neg2sode on 2025/7/23.
//

import UIKit

struct MailUtilities {
    static let recipientMail = "neg2sode@outlook.com"
    
    @discardableResult
    static func send(subject: String, body: String) -> Bool {
        let urlString = "mailto:\(recipientMail)?subject=\(subject)&body=\(body)"
        
        guard let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let mailtoURL = URL(string: encodedUrlString) else {
            print("❌ Failed to create mailto URL.")
            return false
        }
        
        if UIApplication.shared.canOpenURL(mailtoURL) {
            UIApplication.shared.open(mailtoURL)
            return true
        } else {
            return false
        }
    }
}
