//
//  LiveShiftManager.swift
//  WageTrack
//
//  Created by Philip Kurth on 19.02.26.
//

import Foundation
import SwiftUI
import ActivityKit

@Observable
class LiveShiftManager {
    var isTracking = false
    var currentStartTime: Date?
    var currentActivity: Activity<ShiftActivityAttributes>?
    
    func startShift() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let startTime = Date()
        self.currentStartTime = startTime
        self.isTracking = true
        
        let attributes = ShiftActivityAttributes(startTime: startTime)
        let state = ShiftActivityAttributes.ContentState()
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            print("Fehler beim Starten der Live Activity: \(error.localizedDescription)")
        }
    }
    
    func stopShift() {
        Task { @MainActor in
            let state = ShiftActivityAttributes.ContentState()
            await currentActivity?.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: .immediate
            )
            self.isTracking = false
            
            // Wir setzen isTracking nicht hier auf false, sondern erst,
            // wenn die Add-View aufgerufen wurde, damit wir die Zeiten übergeben können.
        }
    }
    
    func reset() {
        isTracking = false
        currentStartTime = nil
        currentActivity = nil
    }
}
