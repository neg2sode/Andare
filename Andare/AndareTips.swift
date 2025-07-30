//
//  AndareTips.swift
//  Andare
//
//  Created by neg2sode on 2025/7/28.
//

import TipKit

struct NotificationFrequencyTip: Tip {
    var title: Text {
        Text("Use High Frequency Cautiously")
    }
    
    var message: Text? {
        Text("By default, Andare checks for alerts every ~4 minutes. If you switch to high, this interval is shortened to ~80 seconds, which may interrupt your workout.")
    }
    
    var image: Image? {
        Image(systemName: "gauge.with.needle")
    }
}
