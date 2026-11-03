//
//  LiveShiftManager.swift
//  WageTrack
//
//  Created by Philip Kurth on 19.02.26.
//

import ActivityKit
import BackgroundTasks
import Foundation
import os
import UIKit

/// Verwaltet die laufende Schicht und spiegelt sie in eine Live Activity.
///
/// Die Schicht selbst (Start, Ende, Lohn) liegt in den UserDefaults und ist die einzige Quelle
/// der Wahrheit. Die Live Activity ist nur eine Anzeige davon: Verschwindet sie (von iOS
/// beendet, weggewischt, App neu installiert), wird sie beim nächsten Öffnen der App neu
/// erstellt. Die Schicht selbst geht dabei nie verloren.
@MainActor
@Observable
final class LiveShiftManager {
    nonisolated static let backgroundRefreshIdentifier = "phil.WageTrack.1.liveUpdate"
    /// So oft wird der Verdienst aktualisiert, solange die App läuft (auch im Hintergrund).
    private static let updateInterval: Duration = .seconds(10)

    /// Start der laufenden (oder gerade gestoppten) Schicht.
    private(set) var startTime: Date?
    /// Wird beim Stoppen gesetzt und bleibt erhalten, bis die Schicht gespeichert oder verworfen wurde.
    private(set) var endTime: Date?
    /// Stundenlohn, mit dem die Schicht aufgezeichnet wird.
    private(set) var hourlyWage: Double = 0

    var isTracking: Bool { startTime != nil && endTime == nil }
    var hasPendingShift: Bool { startTime != nil && endTime != nil }

    /// Abgleiche mit ActivityKit laufen strikt nacheinander, damit sich Starten, Stoppen und
    /// Aktualisieren nie überholen (sonst entstehen doppelte oder verwaiste Activities).
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private var updateLoop: Task<Void, Never>?
    @ObservationIgnored private var backgroundTaskID = UIBackgroundTaskIdentifier.invalid
    @ObservationIgnored private let keepAlive = BackgroundKeepAlive()

    nonisolated private static let logger = Logger(subsystem: "phil.WageTrack.1", category: "LiveShift")

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

    // MARK: - Schicht

    func startShift(hourlyWage: Double) {
        guard !isTracking else { return }
        startTime = .now
        endTime = nil
        self.hourlyWage = hourlyWage
        persist()
        syncActivity()
        startUpdateLoop()
        updateKeepAlive()
    }

    /// Stoppt die Schicht sofort. Sie bleibt als offene Schicht erhalten, bis sie gespeichert
    /// oder verworfen wurde; die Live Activity wird im Hintergrund beendet.
    func stopShift() {
        guard isTracking else { return }
        endTime = .now
        persist()
        stopUpdateLoop()
        keepAlive.stop()
        syncActivity()
    }

    /// Verwirft die laufende bzw. gestoppte Schicht vollständig.
    func reset() {
        startTime = nil
        endTime = nil
        persist()
        stopUpdateLoop()
        keepAlive.stop()
        syncActivity()
    }

    // MARK: - App-Lebenszyklus

    /// Muss aufgerufen werden, wenn die App in den Vordergrund kommt.
    func appDidBecomeActive() {
        // Stellt auch eine Activity wieder her, die iOS inzwischen beendet hat
        syncActivity()
        if isTracking {
            startUpdateLoop()
        }
        updateKeepAlive()
    }

    /// Muss aufgerufen werden, nachdem Einstellungen geändert wurden (Währung, Hintergrund-Aktualisierung).
    func settingsDidChange() {
        syncActivity()
        updateKeepAlive()
    }

    /// Muss aufgerufen werden, wenn die App in den Hintergrund geht (auch beim Sperren).
    func appDidEnterBackground() {
        guard isTracking else {
            stopUpdateLoop()
            return
        }
        // Die periodische Aktualisierung läuft weiter, solange `keepAlive` die App aktiv hält.
        // Ohne Standort-Erlaubnis pausiert iOS die App; die Activity zeigt dann "Stand HH:MM".
        // Zusätzlich sofort ein frisches Update, damit der Sperrbildschirm den aktuellen Betrag
        // zeigt. Die Background-Task gibt der App die Zeit, es noch abzuschließen.
        beginBackgroundTask()
        let sync = syncActivity()
        Task {
            await sync.value
            endBackgroundTask()
        }
        Self.scheduleBackgroundRefresh()
    }

    // MARK: - Live Activity

    /// Bringt die Live Activities in Einklang mit der Schicht. Kann beliebig oft aufgerufen
    /// werden: Die Aufrufe werden nacheinander abgearbeitet und lesen jeweils den aktuellen Zustand.
    @discardableResult
    private func syncActivity() -> Task<Void, Never> {
        let previous = syncTask
        let task = Task {
            await previous?.value
            await reconcileActivities()
        }
        syncTask = task
        return task
    }

    private func reconcileActivities() async {
        let shift = currentShiftAttributes()
        let canStartNew = canStartActivity

        // Genau eine laufende Activity behalten, die zur Schicht passt; alles andere beenden
        // (z.B. Reste einer alten Schicht oder doppelte Activities).
        var current: Activity<ShiftActivityAttributes>?
        for activity in Activity<ShiftActivityAttributes>.activities {
            let belongsToShift = shift.map { activity.attributes.describesSameShift(as: $0) } ?? false
            if belongsToShift, activity.isRunning, current == nil {
                current = activity
                continue
            }
            if belongsToShift, !activity.isRunning, !canStartNew {
                // Von iOS nach 8 Stunden beendet: Bis die App wieder offen ist und eine neue
                // starten darf, bleibt die alte auf dem Sperrbildschirm stehen.
                continue
            }
            Self.logger.info("Beende Activity \(activity.id, privacy: .public) (\(String(describing: activity.activityState), privacy: .public))")
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        guard let shift else { return }
        if let current {
            await current.update(shift.content())
        } else if canStartNew {
            requestActivity(for: shift)
        }
    }

    private func currentShiftAttributes() -> ShiftActivityAttributes? {
        guard isTracking, let startTime else { return nil }
        return ShiftActivityAttributes(startTime: startTime, hourlyWage: hourlyWage, currencyCode: AppSettings.currencyCode)
    }

    /// Hält die App nur während einer laufenden Schicht aktiv – und nur, wenn es erwünscht ist.
    private func updateKeepAlive() {
        if isTracking, AppSettings.backgroundUpdatesEnabled {
            keepAlive.start()
        } else {
            keepAlive.stop()
        }
    }

    /// Neue Activities erlaubt iOS nur, solange die App im Vordergrund ist.
    private var canStartActivity: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled && UIApplication.shared.applicationState != .background
    }

    private func requestActivity(for attributes: ShiftActivityAttributes) {
        do {
            let activity = try Activity.request(attributes: attributes, content: attributes.content())
            Self.logger.info("Activity gestartet: \(activity.id, privacy: .public)")
        } catch {
            // Das Tracking läuft trotzdem weiter, auch wenn die Live Activity fehlschlägt
            Self.logger.error("Live Activity konnte nicht gestartet werden: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Periodische Aktualisierung

    private func startUpdateLoop() {
        guard updateLoop == nil else { return }
        updateLoop = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.updateInterval)
                guard !Task.isCancelled, let self else { return }
                await self.syncActivity().value
            }
        }
    }

    private func stopUpdateLoop() {
        updateLoop?.cancel()
        updateLoop = nil
    }

    // MARK: - Hintergrund

    private func beginBackgroundTask() {
        guard backgroundTaskID == .invalid else { return }
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "LiveActivityUpdate") { [weak self] in
            // Läuft die Zeit ab, muss die Task beendet werden, sonst beendet iOS die App
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }

    /// Bittet iOS, die App im Hintergrund kurz zu wecken, um den Verdienst zu aktualisieren.
    /// iOS entscheidet selbst, wann (und ob) das passiert – frühestens nach 15 Minuten.
    nonisolated static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.error("Hintergrund-Aktualisierung konnte nicht geplant werden: \(error.localizedDescription, privacy: .public)")
        }
    }

    nonisolated static func refreshActivitiesInBackground() async {
        let activities = Activity<ShiftActivityAttributes>.activities.filter(\.isRunning)
        guard !activities.isEmpty else { return }
        for activity in activities {
            await activity.update(activity.attributes.content())
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
        if startTime == nil,
           let activity = Activity<ShiftActivityAttributes>.activities.first(where: \.isRunning),
           activity.attributes.hourlyWage > 0 {
            startTime = activity.attributes.startTime
            hourlyWage = activity.attributes.hourlyWage
            persist()
        }
    }
}

private extension Activity {
    /// Wird die Activity noch angezeigt und kann aktualisiert werden?
    nonisolated var isRunning: Bool {
        activityState == .active || activityState == .stale
    }
}
