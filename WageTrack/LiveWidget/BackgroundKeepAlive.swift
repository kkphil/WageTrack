//
//  BackgroundKeepAlive.swift
//  WageTrack
//

import CoreLocation
import os

/// Hält die App während einer laufenden Schicht im Hintergrund am Laufen, damit sie den
/// Verdienst in der Live Activity weiter aktualisieren kann.
///
/// iOS pausiert Apps im Hintergrund nach wenigen Sekunden, und ohne Server (Push) kann nur die
/// laufende App eine Live Activity aktualisieren. Solange die App Standort-Updates empfängt,
/// pausiert iOS sie nicht. Dafür genügt die gröbste Genauigkeit (Funkzellen statt GPS); die
/// Positionen selbst werden nicht verwendet oder gespeichert.
final class BackgroundKeepAlive: NSObject {
    private let locationManager = CLLocationManager()
    private var wantsToRun = false
    private var isUpdating = false

    nonisolated private static let logger = Logger(subsystem: "phil.WageTrack.1", category: "KeepAlive")

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 1_000
        // Sonst pausiert iOS die Updates, sobald man sich nicht bewegt – und damit die App
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    /// Fragt beim ersten Mal nach der Standort-Erlaubnis. Wird sie verweigert, läuft die Schicht
    /// ganz normal weiter; der Verdienst wird dann nur aktualisiert, während die App offen ist.
    func start() {
        wantsToRun = true
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdates()
        default:
            Self.logger.info("Standort nicht erlaubt, Verdienst wird im Hintergrund nicht aktualisiert")
        }
    }

    func stop() {
        wantsToRun = false
        guard isUpdating else { return }
        isUpdating = false
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        Self.logger.info("Hintergrund-Aktualisierung beendet")
    }

    private func startUpdates() {
        guard !isUpdating else { return }
        isUpdating = true
        // Erfordert "location" in UIBackgroundModes (Info.plist), sonst stürzt die App hier ab
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.startUpdatingLocation()
        Self.logger.info("Hintergrund-Aktualisierung aktiv")
    }
}

extension BackgroundKeepAlive: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if wantsToRun { startUpdates() }
            default:
                // Erlaubnis entzogen: iOS liefert keine Updates mehr, beim erneuten Erlauben neu starten
                isUpdating = false
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Die Positionen werden nicht gebraucht
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // Z.B. gerade kein Standort verfügbar: Die Updates laufen trotzdem weiter
        Self.logger.debug("Standortfehler: \(error.localizedDescription, privacy: .public)")
    }
}
