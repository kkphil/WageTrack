import Foundation
import SwiftData

@Model
final class Shift {
    var date: Date
    var startTime: Date
    var endTime: Date
    var breakMinutes: Int
    var hourlyWage: Double
    var tip: Double
    var isArchived: Bool = false

    init(date: Date, startTime: Date, endTime: Date, breakMinutes: Int, hourlyWage: Double, tip: Double = 0, isArchived: Bool = false) {
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.breakMinutes = breakMinutes
        self.hourlyWage = hourlyWage
        self.tip = tip
        self.isArchived = isArchived
    }

    /// Bezahlte Arbeitszeit in Stunden (ohne Pause).
    var workedHours: Double {
        durationInHours(from: startTime, to: endTime, breakMinutes: breakMinutes)
    }

    /// Verdienst aus dem Stundenlohn, ohne Trinkgeld.
    var wageEarnings: Double {
        roundedToCents(workedHours * hourlyWage)
    }

    /// Gesamtverdienst inkl. Trinkgeld, auf Cent gerundet.
    var totalEarnings: Double {
        roundedToCents(wageEarnings + tip)
    }
}
