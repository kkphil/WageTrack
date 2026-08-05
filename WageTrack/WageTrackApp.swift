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
    var body: some Scene {
            WindowGroup {
                ContentView()
            }
            .modelContainer(for: Shift.self)
        }
}
