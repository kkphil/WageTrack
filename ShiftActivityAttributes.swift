//
//  ShiftActivityAttributes.swift
//  WageTrack
//
//  Created by Philip Kurth on 19.02.26.
//

import ActivityKit
import Foundation

struct ShiftActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Hier könnten sich verändernde Daten rein, für einen simplen Timer brauchen wir hier aber nichts zwingend.
    }
    
    // Statische Daten, die beim Start feststehen
    var startTime: Date
}
