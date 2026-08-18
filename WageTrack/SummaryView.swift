//
//  SummaryView.swift
//  WageTrack
//
//  Created by Philip Kurth on 05.03.26.
//

import Foundation
import SwiftUI
import SwiftData

struct SummaryView: View {
    @Query(sort: \Shift.date, order: .reverse) private var shifts: [Shift]
    
    private var totalHours: Double {
        shifts.reduce(0) { $0 + durationInHours(from: $1.startTime, to: $1.endTime) }
    }
    
    // NEU: Wandelt die Dezimalstunden (z.B. 25.5) in einen String (25:30h) um
    private var totalHoursFormatted: String {
        let hours = Int(totalHours)
        let minutes = Int(round((totalHours - Double(hours)) * 60))
        
        // Verhindert Anzeige von "25:60h" durch Rundung, macht stattdessen "26:00h" daraus
        if minutes == 60 {
            return String(format: "%d:00h", hours + 1)
        } else {
            return String(format: "%d:%02dh", hours, minutes)
        }
    }
    
    private var totalShifts: Int { shifts.count }
    
    private var totalEarnings: Double {
        shifts.reduce(0) { $0 + $1.totalEarnings }
    }
    
    private var totalTips: Double {
        shifts.reduce(0) { $0 + $1.tip }
    }
    
    private var totalEarningsWithoutTips: Double {
        shifts.reduce(0) { $0 + ($1.totalEarnings - $1.tip) }
    }
    
    private var earningsThisMonthWithoutTips: Double {
        let calendar = Calendar.current
        let now = Date()
        let currentMonthIndex = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        return shifts.filter { calendar.component(.month, from: $0.date) == currentMonthIndex && calendar.component(.year, from: $0.date) == currentYear }
            .reduce(0) { $0 + ($1.totalEarnings - $1.tip) }
    }
    
    private var earningsThisYearWithoutTips: Double {
        let currentYear = Calendar.current.component(.year, from: Date())
        return shifts.filter { Calendar.current.component(.year, from: $0.date) == currentYear }
            .reduce(0) { $0 + ($1.totalEarnings - $1.tip) }
    }
    
    private var avgEarningsPerMonthTillNow: Double {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonthIndex = calendar.component(.month, from: now)

        let yearShifts = shifts.filter { calendar.component(.year, from: $0.date) == currentYear }
        let totalYearlyEarnings = yearShifts.reduce(0) { $0 + ($1.totalEarnings - $1.tip) }
        
        guard currentMonthIndex > 0 else { return 0 }
        return totalYearlyEarnings / Double(currentMonthIndex)
    }
    
    private var avgEarningsPerMonthThisYear: Double {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)

        let yearShifts = shifts.filter { calendar.component(.year, from: $0.date) == currentYear }
        let totalYearlyEarnings = yearShifts.reduce(0) { $0 + ($1.totalEarnings - $1.tip) }
        
        return totalYearlyEarnings / 12.0
    }

    var body: some View {
        VStack {
            HStack {
                // Hier rufen wir jetzt die neue formatierte Eigenschaft auf
                BoxView(title: "Arbeitszeit", value: totalHoursFormatted)
                BoxView(title: "Netto", value: String(format: "%.2f€", totalEarningsWithoutTips))
                BoxView(title: "Tipps", value: String(format: "%.2f€", totalTips))
                BoxView(title: "Gesamt", value: String(format: "%.2f€", totalEarnings))
            }
            HStack {
                BoxView(title: "Monat (Net)", value: String(format: "%.2f€", earningsThisMonthWithoutTips))
                BoxView(title: "Jahr (Net)", value: String(format: "%.2f€", earningsThisYearWithoutTips))
                BoxView(title: "Ø Aktuell", value: String(format: "%.2f€", avgEarningsPerMonthTillNow))
                BoxView(title: "Ø Jahr/12", value: String(format: "%.2f€", avgEarningsPerMonthThisYear))
            }
        }
    }
}
