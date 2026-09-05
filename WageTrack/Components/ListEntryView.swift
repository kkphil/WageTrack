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
    var body: some View {
        HStack {
            VPTimestampView(date: shift.date)
            
            VStack(alignment: .leading) {
                Text(durationInTimeString(from: shift.startTime, to: shift.endTime))
                    .font(.headline)
                Text("Lohn: \((shift.totalEarnings / durationInHours(from: shift.startTime, to: shift.endTime)), specifier: "%.2f")€/h")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            if shift.isArchived {
                Image(systemName: "archivebox")
            }
            Spacer()
    
            Text("\(shift.totalEarnings, specifier: "%.2f") €")
                .fontWeight(.bold)
                .foregroundStyle(shift.tip > 0 ? .blue : .green)
        }.opacity(shift.isArchived ? 0.4 : 1.0)
    }
}
