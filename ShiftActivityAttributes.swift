//
//  ShiftActivityAttributes.swift
//  WageTrack
//
//  Created by Philip Kurth on 19.02.26.
//

import ActivityKit
import Foundation

// Wird von App und Widget-Extension gemeinsam genutzt. `nonisolated`, weil ActivityKit die
// Daten auf eigenen Hintergrund-Threads kodiert und dekodiert (in der App gilt sonst
// standardmäßig MainActor).
nonisolated struct ShiftActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        // Live Activities werden vom System gerendert, das nur seine eigenen Timer-Texte
        // selbst weiterzählen kann. Der Verdienst wird daher von der App berechnet.
        var earnings: Double
        var updatedAt: Date
    }

    // Statische Daten, die beim Start feststehen
    var startTime: Date
    var hourlyWage: Double
}

nonisolated extension ShiftActivityAttributes {
    /// Nach dieser Zeit ohne Aktualisierung gilt der angezeigte Verdienst als veraltet.
    static let staleInterval: TimeInterval = 60

    /// Verdienst seit `startTime` bis `date`, abgerundet auf volle Cent.
    static func earnings(since startTime: Date, hourlyWage: Double, at date: Date = .now) -> Double {
        let hours = max(0, date.timeIntervalSince(startTime)) / 3_600
        return (hours * hourlyWage * 100).rounded(.down) / 100
    }

    func content(at date: Date = .now) -> ActivityContent<ContentState> {
        let state = ContentState(
            earnings: Self.earnings(since: startTime, hourlyWage: hourlyWage, at: date),
            updatedAt: date
        )
        return ActivityContent(state: state, staleDate: date.addingTimeInterval(Self.staleInterval))
    }

    /// Gehört eine Activity zu dieser Schicht? (Zeitstempel mit Toleranz, da sie kodiert wurden)
    func describesSameShift(as other: ShiftActivityAttributes) -> Bool {
        abs(startTime.timeIntervalSince(other.startTime)) < 1 && hourlyWage == other.hourlyWage
    }
}

// MARK: - Tolerantes Dekodieren
// Eine Activity, die noch von einer älteren App-Version mit anderem Datenformat gestartet
// wurde, soll trotzdem dekodierbar bleiben. Sonst kann das Widget sie nicht darstellen und
// die App sie nicht mehr finden, um sie zu beenden.

nonisolated extension ShiftActivityAttributes {
    enum CodingKeys: String, CodingKey {
        case startTime, hourlyWage
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startTime = try container.decode(Date.self, forKey: .startTime)
        hourlyWage = try container.decodeIfPresent(Double.self, forKey: .hourlyWage) ?? 0
    }
}

nonisolated extension ShiftActivityAttributes.ContentState {
    enum CodingKeys: String, CodingKey {
        case earnings, updatedAt
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        earnings = try container.decodeIfPresent(Double.self, forKey: .earnings) ?? 0
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .distantPast
    }
}
