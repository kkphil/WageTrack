//
//  LiveInfoView.swift
//  WageTrack
//
//  Created by Philip Kurth on 22.02.26.
//

import Foundation
import SwiftUI

struct LiveInfoView: View {
    @Binding var liveManager: LiveShiftManager
    
    var body: some View {
        Group {
            if !liveManager.isTracking {
                EmptyView()
            } else {
                VStack {
                    Text("Laufende Arbeit")
                        .font(.largeTitle)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                
                    TimelineView(.periodic(from: .now, by: 3.0)) { context in
                        HStack {
                            VPTimestampView(date: liveManager.currentStartTime!, color: Color(.red))
                            
                            VStack(alignment: .leading) {
                                
                                Text(durationInTimeString(from: liveManager.currentStartTime!))
                                    .font(.headline)
                                
                                Text("Lohn: \((durationInHours(from: liveManager.currentStartTime!)*14 / durationInHours(from: liveManager.currentStartTime!)), specifier: "%.2f")€/h")
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
                            
                            Text("\(durationInHours(from: liveManager.currentStartTime!)*14, specifier: "%.2f") €")
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
    }
}
