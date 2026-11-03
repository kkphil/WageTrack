//
//  LiveInfoView.swift
//  WageTrack
//
//  Created by Philip Kurth on 22.02.26.
//

import Foundation
import SwiftUI

struct LiveInfoView: View {
    var liveManager: LiveShiftManager
    @AppStorage(AppSettings.Keys.currencyCode) private var currencyCode = AppSettings.systemCurrencyCode

    var body: some View {
        if liveManager.isTracking, let startTime = liveManager.startTime {
            VStack {
                Text("Laufende Arbeit")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    HStack {
                        VPTimestampView(date: startTime, color: Color(.red))

                        VStack(alignment: .leading) {
                            Text(elapsedTimeString(from: startTime, to: context.date))
                                .font(.headline)
                            Text("Lohn: \(liveManager.hourlyWage.currency(currencyCode))/h")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "record.circle")
                            .foregroundStyle(.red)
                            .symbolEffect(.pulse)
                            .bold()
                        Text("Live")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)

                        Spacer()

                        let earnings = ShiftActivityAttributes.earnings(
                            since: startTime,
                            hourlyWage: liveManager.hourlyWage,
                            at: context.date
                        )
                        Text(earnings.currency(currencyCode))
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }
}
