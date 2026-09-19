//
//  LiveShiftManager.swift
//  WageTrack
//
//  Created by Philip Kurth on 19.02.26.
//

import Foundation
import SwiftUI
import ActivityKit
import BackgroundTasks

@MainActor
@Observable
class LiveShiftManager {
    static let backgroundRefreshIdentifier = "phil.WageTrack.1.liveUpdate"

    /// Start der laufenden (oder gerade gestoppten) Schicht.
    private(set) var startTime: Date?
    /// Wird beim Stoppen gesetzt und bleibt erhalten, bis die Schicht gespeichert oder verworfen wurde.
    private(set) var endTime: Date?
    private(set) var hourlyWage: Double = 14.0

    var isTracking: Bool { startTime != nil && endTime == nil }
    var hasPendingShift: Bool { startTime != nil && endTime != nil }

    private var currentActivity: Activity<ShiftActivityAttributes>?
    private var updateTask: Task<Void, Never>?

    // Der Zustand wird in den UserDefaults gespeichert, damit er überlebt, wenn iOS die App
    // im Hintergrund beendet (passiert bei langen Schichten praktisch immer).
    private enum Keys {
        static let startTime = "liveShift.startTime"
        static let endTime = "liveShift.endTime"
        static let hourlyWage = "liveShift.hourlyWage"
    }

    init() {
        restore()
    }

    // MARK: - Öffentliche API

    func startShift(hourlyWage: Double) {
        let startTime = Date()
        self.startTime = startTime
        self.endTime = nil
        self.hourlyWage = hourlyWage
        persist()

        Task {
            // Eventuell übrig gebliebene Activities (z.B. nach einem Absturz) aufräumen
            await endAllActivities()
            startActivity()
            startUpdateLoop()
        }
    }

    func stopShift() async {
        guard isTracking else { return }
        endTime = Date()
        persist()
        stopUpdateLoop()
        await endAllActivities()
    }

    /// Verwirft die laufende bzw. gestoppte Schicht vollständig.
    func reset() async {
        stopUpdateLoop()
        await endAllActivities()
        startTime = nil
        endTime = nil
        persist()
    }

    /// Muss aufgerufen werden, wenn die App in den Vordergrund kommt.
    func appDidBecomeActive() {
        guard isTracking else { return }
        reattachOrRestartActivity()
        startUpdateLoop()
    }

    /// Muss aufgerufen werden, wenn die App in den Hintergrund geht.
    func appDidEnterBackground() {
        stopUpdateLoop()
        guard isTracking else { return }
        Task { await updateActivity() }
        Self.scheduleBackgroundRefresh()
    }

    // MARK: - Live Activity

    private func startActivity() {
        guard let startTime, ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = ShiftActivityAttributes(startTime: startTime, hourlyWage: hourlyWage)
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: attributes.contentState(), staleDate: nil)
            )
        } catch {
            // Tracking läuft trotzdem weiter, auch wenn die Live Activity fehlschlägt
            print("Fehler beim Starten der Live Activity: \(error.localizedDescription)")
        }
    }

    /// Verbindet sich nach einem App-Neustart wieder mit der laufenden Activity. Hat iOS die
    /// Activity beendet (Limit von 8 Stunden), wird eine neue gestartet.
    private func reattachOrRestartActivity() {
        let running = Activity<ShiftActivityAttributes>.activities.first {
            $0.activityState == .active || $0.activityState == .stale
        }
        if let running {
            currentActivity = running
        } else {
            currentActivity = nil
            startActivity()
        }
    }

    private func updateActivity() async {
        guard let activity = currentActivity else { return }
        let state = activity.attributes.contentState()
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    private func endAllActivities() async {
        for activity in Activity<ShiftActivityAttributes>.activities {
            await activity.end(
                ActivityContent(state: activity.attributes.contentState(), staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        currentActivity = nil
    }

    // MARK: - Periodische Aktualisierung

    /// Solange die App läuft, wird der Verdienst in der Live Activity alle 30 Sekunden aktualisiert.
    private func startUpdateLoop() {
        updateTask?.cancel()
        updateTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.updateActivity()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private func stopUpdateLoop() {
        updateTask?.cancel()
        updateTask = nil
    }

    // MARK: - Hintergrund

    /// Bittet iOS, die App im Hintergrund kurz zu wecken, um den Verdienst zu aktualisieren.
    /// iOS entscheidet selbst, wann (und ob) das passiert – typischerweise alle 15+ Minuten.
    nonisolated static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Hintergrund-Aktualisierung konnte nicht geplant werden: \(error.localizedDescription)")
        }
    }

    nonisolated static func refreshActivitiesInBackground() async {
        let activities = Activity<ShiftActivityAttributes>.activities.filter { $0.activityState == .active }
        guard !activities.isEmpty else { return }
        for activity in activities {
            await activity.update(ActivityContent(state: activity.attributes.contentState(), staleDate: nil))
        }
        scheduleBackgroundRefresh()
    }

    // MARK: - Persistenz

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(startTime, forKey: Keys.startTime)
        defaults.set(endTime, forKey: Keys.endTime)
        defaults.set(hourlyWage, forKey: Keys.hourlyWage)
    }

    private func restore() {
        let defaults = UserDefaults.standard
        startTime = defaults.object(forKey: Keys.startTime) as? Date
        endTime = defaults.object(forKey: Keys.endTime) as? Date
        if let wage = defaults.object(forKey: Keys.hourlyWage) as? Double {
            hourlyWage = wage
        }

        // Fallback: Es läuft noch eine Activity, aber der gespeicherte Zustand fehlt
        if startTime == nil, let activity = Activity<ShiftActivityAttributes>.activities.first {
            startTime = activity.attributes.startTime
            hourlyWage = activity.attributes.hourlyWage
            persist()
        }
    }
}
