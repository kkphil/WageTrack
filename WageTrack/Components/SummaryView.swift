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
    @AppStorage(AppSettings.Keys.currencyCode) private var currencyCode = AppSettings.systemCurrencyCode

    var body: some View {
        // Einmal pro Darstellung berechnen statt für jede Kachel neu über alle Schichten zu laufen
        let summary = Summary(shifts: shifts.filter { !$0.isArchived })

        VStack {
            HStack {
                BoxView(title: "Gesamt", value: summary.totalEarnings.currency(currencyCode))
                BoxView(title: "Netto", value: summary.wageEarnings.currency(currencyCode))
                BoxView(title: "Tipps", value: summary.tips.currency(currencyCode))
                BoxView(title: "Ø pro Std.", value: summary.earningsPerHour.currency(currencyCode))
            }
            HStack {
                BoxView(title: "Monat (Net)", value: summary.wageEarningsThisMonth.currency(currencyCode))
                BoxView(title: "Jahr (Net)", value: summary.wageEarningsThisYear.currency(currencyCode))
                BoxView(title: "Ø Aktuell", value: summary.monthlyAverageSoFar.currency(currencyCode))
                BoxView(title: "Ø Jahr/12", value: summary.monthlyAverageFullYear.currency(currencyCode))
            }
        }
        .padding(.horizontal)
    }
}

/// Kennzahlen über alle (nicht archivierten) Schichten.
private struct Summary {
    var totalEarnings = 0.0
    /// Verdienst ohne Trinkgeld
    var wageEarnings = 0.0
    var tips = 0.0
    var hours = 0.0
    var wageEarningsThisMonth = 0.0
    var wageEarningsThisYear = 0.0
    /// Aktueller Monat des Jahres (1...12)
    var currentMonth = 1

    init(shifts: [Shift], now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.dateComponents([.year, .month], from: now)
        currentMonth = today.month ?? 1

        for shift in shifts {
            totalEarnings += shift.totalEarnings
            wageEarnings += shift.wageEarnings
            tips += shift.tip
            hours += shift.workedHours

            let date = calendar.dateComponents([.year, .month], from: shift.date)
            guard date.year == today.year else { continue }
            wageEarningsThisYear += shift.wageEarnings
            if date.month == today.month {
                wageEarningsThisMonth += shift.wageEarnings
            }
        }
    }

    /// Durchschnittlicher Verdienst pro Stunde inkl. Trinkgeld (0, solange keine Arbeitszeit erfasst ist).
    var earningsPerHour: Double {
        hours > 0 ? totalEarnings / hours : 0
    }

    /// Durchschnitt pro Monat über die bisher vergangenen Monate des Jahres.
    var monthlyAverageSoFar: Double {
        wageEarningsThisYear / Double(max(1, currentMonth))
    }

    /// Durchschnitt pro Monat, auf das ganze Jahr gerechnet.
    var monthlyAverageFullYear: Double {
        wageEarningsThisYear / 12
    }
}
