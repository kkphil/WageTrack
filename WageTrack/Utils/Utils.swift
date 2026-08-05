//
//  Utils.swift
//  WageTrack
//
//  Created by Philip Kurth on 22.02.26.
//

import Foundation

public func durationInTimeString(from start: Date, to end: Date = Date()) -> String {
    var diffence = end.timeIntervalSince(start)
    
    if diffence < 0 {
        diffence += 86_400
    }
    
    let minutes = Int(diffence.truncatingRemainder(dividingBy: 3_600) / 60)
    let hours = Int(diffence.truncatingRemainder(dividingBy: 86_400) / 3_600)
    
    return String(format: "%02d:%02d", hours, minutes)
}

public func durationInHours(from start: Date, to end: Date = Date(), breakMinutes: Int = 0) -> Double {
    var diffence = end.timeIntervalSince(start)
    if diffence < 0 {
        diffence += 86_400
    }
    diffence = max(0, diffence - Double(breakMinutes)*60)
    
    return diffence.truncatingRemainder(dividingBy: 86_400) / 3_600
}
