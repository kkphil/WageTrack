//
//  Utils.swift
//  WageTrack
//
//  Created by Philip Kurth on 22.02.26.
//

import Foundation

public func durationInTimeString(from start: Date, to end: Date = Date()) -> String {
    var difference = end.timeIntervalSince(start)
    
    // Wenn die Differenz negativ ist, bedeutet das, dass end vor start liegt
    // Das kann passieren, wenn eine Schicht über Mitternacht geht
    if difference < 0 {
        difference += 86_400 // Füge 24 Stunden hinzu
    }
    
    let minutes = Int((difference.truncatingRemainder(dividingBy: 3_600)) / 60)
    let hours = Int((difference.truncatingRemainder(dividingBy: 86_400)) / 3_600)
    
    return String(format: "%02d:%02d", hours, minutes)
}

public func durationInHours(from start: Date, to end: Date = Date(), breakMinutes: Int = 0) -> Double {
    var difference = end.timeIntervalSince(start)
    
    // Wenn die Differenz negativ ist, bedeutet das, dass end vor start liegt
    // Das kann passieren, wenn eine Schicht über Mitternacht geht
    if difference < 0 {
        difference += 86_400 // Füge 24 Stunden hinzu
    }
    
    // Subtrahiere die Pausenzeit (in Sekunden)
    difference = max(0, difference - Double(breakMinutes) * 60)
    
    // Berechne die Stunden
    return (difference.truncatingRemainder(dividingBy: 86_400)) / 3_600
}
