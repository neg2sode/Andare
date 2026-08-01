//
//  LogEntry.swift
//  Andare
//
//  Created by neg2sode on 2025/5/2.
//

import Foundation

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String

    // Formatter for display
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS" // Example format
        return formatter
    }()

    var formattedTimestamp: String {
        LogEntry.dateFormatter.string(from: timestamp)
    }
}
