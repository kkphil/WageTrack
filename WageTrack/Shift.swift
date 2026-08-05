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
    
    init(date: Date = .now, startTime: Date = .now, endTime: Date = .now.addingTimeInterval(28800), breakMinutes: Int = 30, hourlyWage: Double = 14.00, tip: Double = 0) {
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.breakMinutes = breakMinutes
        self.hourlyWage = hourlyWage
        self.tip = tip
    }
    
    
    // Berechnet den Gesamtverdienst und rundet auf 2 Nachkommastellen (Cents)
    var totalEarnings: Double {
        let duration = durationInHours(from: startTime, to: endTime, breakMinutes: breakMinutes)
        let earnings = (duration * hourlyWage) + tip
        return (earnings * 100).rounded() / 100
    }
}
