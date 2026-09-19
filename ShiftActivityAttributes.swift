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
        // Live Activities rendern nur Snapshots. Der Verdienst kann sich daher nicht selbst
        // hochzählen, sondern wird von der App regelmäßig neu berechnet und hier hinterlegt.
        var earnings: Double
        var updatedAt: Date
    }

    // Statische Daten, die beim Start feststehen
    var startTime: Date
    var hourlyWage: Double
}

extension ShiftActivityAttributes {
    /// Verdienst seit `startTime` bis `date`, gerundet auf Cent.
    static func earnings(since startTime: Date, hourlyWage: Double, at date: Date = .now) -> Double {
        let hours = max(0, date.timeIntervalSince(startTime)) / 3_600
        return (hours * hourlyWage * 100).rounded() / 100
    }

    func contentState(at date: Date = .now) -> ContentState {
        ContentState(
            earnings: Self.earnings(since: startTime, hourlyWage: hourlyWage, at: date),
            updatedAt: date
        )
    }
}
