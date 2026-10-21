//
//  Utils.swift
//  WageTrack
//
//  Created by Philip Kurth on 22.02.26.
//

import Foundation

/// Dauer einer Schicht in Sekunden, abzüglich der Pause.
///
/// Start und Ende werden als Uhrzeiten verstanden: Liegt das Ende vor dem Start, geht die
/// Schicht über Mitternacht. Das Ergebnis liegt daher immer zwischen 0 und 24 Stunden,
/// auch wenn die Datumsanteile der beiden Zeitpunkte nicht zusammenpassen.
public func shiftDuration(from start: Date, to end: Date, breakMinutes: Int = 0) -> TimeInterval {
    let day: TimeInterval = 86_400
    var difference = end.timeIntervalSince(start).truncatingRemainder(dividingBy: day)
    if difference < 0 {
        difference += day
    }
    return max(0, difference - Double(max(0, breakMinutes)) * 60)
}

/// Dauer als "HH:mm".
public func durationInTimeString(from start: Date, to end: Date = Date(), breakMinutes: Int = 0) -> String {
    timeString(seconds: shiftDuration(from: start, to: end, breakMinutes: breakMinutes))
}

public func durationInHours(from start: Date, to end: Date = Date(), breakMinutes: Int = 0) -> Double {
    shiftDuration(from: start, to: end, breakMinutes: breakMinutes) / 3_600
}

/// Tatsächlich vergangene Zeit als "HH:mm" – ohne Umbruch nach 24 Stunden.
public func elapsedTimeString(from start: Date, to end: Date = Date()) -> String {
    timeString(seconds: max(0, end.timeIntervalSince(start)))
}

private func timeString(seconds: TimeInterval) -> String {
    let totalMinutes = Int(seconds / 60)
    return String(format: "%02d:%02d", totalMinutes / 60, totalMinutes % 60)
}

/// Rundet einen Betrag auf volle Cent.
public func roundedToCents(_ amount: Double) -> Double {
    (amount * 100).rounded() / 100
}
