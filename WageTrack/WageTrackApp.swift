//
//  WageTrackApp.swift
//  WageTrack
//
//  Created by Philip Kurth on 17.01.26.
//

import SwiftUI
import SwiftData

@main
struct WageTrackApp: App {
    @State private var liveManager = LiveShiftManager()

    var body: some Scene {
        WindowGroup {
            ContentView(liveManager: liveManager)
        }
        .modelContainer(for: Shift.self)
        // Weckt die App gelegentlich im Hintergrund, um den Verdienst in der Live Activity zu aktualisieren
        .backgroundTask(.appRefresh(LiveShiftManager.backgroundRefreshIdentifier)) {
            await LiveShiftManager.refreshActivitiesInBackground()
        }
    }
}
