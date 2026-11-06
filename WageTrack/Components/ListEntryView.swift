//
//  ListEntryView.swift
//  WageTrack
//
//  Created by Philip Kurth on 05.03.26.
//

import Foundation
import SwiftUI

struct ListEntryView: View {
    let shift: Shift
    @AppStorage(AppSettings.Keys.currencyCode) private var currencyCode = AppSettings.systemCurrencyCode

    var body: some View {
        HStack {
            VPTimestampView(date: shift.date)
            
            VStack(alignment: .leading) {
                Text(durationInTimeString(from: shift.startTime, to: shift.endTime, breakMinutes: shift.breakMinutes))
                    .font(.headline)
                Text("Lohn: \(effectiveHourlyWage.currency(currencyCode))/h")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            if shift.isArchived {
                Image(systemName: "archivebox")
            }
            Spacer()
    
            Text(shift.totalEarnings.currency(currencyCode))
                .fontWeight(.bold)
                .foregroundStyle(shift.tip > 0 ? .blue : .green)
        }.opacity(shift.isArchived ? 0.4 : 1.0)
    }

    // Verdienst pro Stunde inkl. Trinkgeld; ohne Arbeitszeit (Start == Ende) den Stundenlohn anzeigen
    private var effectiveHourlyWage: Double {
        let hours = shift.workedHours
        return hours > 0 ? shift.totalEarnings / hours : shift.hourlyWage
    }
}
