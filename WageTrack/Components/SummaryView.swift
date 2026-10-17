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
    
    private var activeShifts: [Shift] {
        shifts.filter { !$0.isArchived }
    }

    public var totalHours: Double {
        activeShifts.reduce(0) { $0 + durationInHours(from: $1.startTime, to: $1.endTime) - (Double($1.breakMinutes) / 60.0)}
    }
    
    
    private var avgErningsPerHour: String {
        return String(format: "%.2f€", (totalEarnings / totalHours))
    }
    
    private var totalShifts: Int { activeShifts.count }
    
    private var totalEarnings: Double {
        activeShifts.reduce(0) { $0 + $1.totalEarnings }
    }
    
    private var totalTips: Double {
        activeShifts.reduce(0) { $0 + $1.tip }
    }
    
    private var totalEarningsWithoutTips: Double {
        activeShifts.reduce(0) { $0 + ($1.totalEarnings - $1.tip) }
    }
    
    private var earningsThisMonthWithoutTips: Double {
        let calendar = Calendar.current
        let now = Date()
        let currentMonthIndex = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        return activeShifts.filter { calendar.component(.month, from: $0.date) == currentMonthIndex && calendar.component(.year, from: $0.date) == currentYear }
            .reduce(0) { $0 + ($1.totalEarnings - $1.tip) }
    }
    
    private var earningsThisYearWithoutTips: Double {
        let currentYear = Calendar.current.component(.year, from: Date())
        return activeShifts.filter { Calendar.current.component(.year, from: $0.date) == currentYear }
            .reduce(0) { $0 + ($1.totalEarnings - $1.tip) }
    }
    
    private var avgEarningsPerMonthTillNow: Double {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonthIndex = calendar.component(.month, from: now)

        let yearShifts = activeShifts.filter { calendar.component(.year, from: $0.date) == currentYear }
        let totalYearlyEarnings = yearShifts.reduce(0) { $0 + ($1.totalEarnings - $1.tip) }
        
        guard currentMonthIndex > 0 else { return 0 }
        return totalYearlyEarnings / Double(currentMonthIndex)
    }
    
    private var avgEarningsPerMonthThisYear: Double {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)

        let yearShifts = activeShifts.filter { calendar.component(.year, from: $0.date) == currentYear }
        let totalYearlyEarnings = yearShifts.reduce(0) { $0 + ($1.totalEarnings - $1.tip) }
        
        return totalYearlyEarnings / 12.0
    }

    var body: some View {
        VStack {
            HStack {
                BoxView(title: "Gesamt", value: String(format: "%.2f€", totalEarnings))
                BoxView(title: "Netto", value: String(format: "%.2f€", totalEarningsWithoutTips))
                BoxView(title: "Tipps", value: String(format: "%.2f€", totalTips))
                BoxView(title: "Ø €/h", value: avgErningsPerHour)
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
