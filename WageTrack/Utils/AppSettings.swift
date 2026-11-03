//
//  AppSettings.swift
//  WageTrack
//

import Foundation

/// Benutzereinstellungen der App. Die Werte liegen in den UserDefaults; Views binden sich
/// über `@AppStorage` mit den Schlüsseln aus `Keys` daran.
nonisolated enum AppSettings {
    enum Keys {
        static let currencyCode = "settings.currencyCode"
        static let defaultHourlyWage = "settings.defaultHourlyWage"
        static let defaultBreakMinutes = "settings.defaultBreakMinutes"
        static let useLastShiftAsTemplate = "settings.useLastShiftAsTemplate"
        static let backgroundUpdatesEnabled = "settings.backgroundUpdatesEnabled"
    }

    /// Längste auswählbare Pause in Minuten.
    static let maxBreakMinutes = 120
    /// Vorbelegte Dauer einer manuell hinzugefügten Schicht (Ende = jetzt).
    static let manualShiftDuration: TimeInterval = 6 * 3_600

    /// Währung der Region des Geräts; wird verwendet, solange keine Währung gewählt wurde.
    static var systemCurrencyCode: String {
        Locale.current.currency?.identifier ?? "EUR"
    }

    static var currencyCode: String {
        UserDefaults.standard.string(forKey: Keys.currencyCode) ?? systemCurrencyCode
    }

    /// Stundenlohn für neue Schichten; `nil`, solange noch keiner festgelegt wurde.
    static var defaultHourlyWage: Double? {
        guard let wage = UserDefaults.standard.object(forKey: Keys.defaultHourlyWage) as? Double,
              wage.isFinite, wage >= 0 else { return nil }
        return wage
    }

    static var defaultBreakMinutes: Int {
        max(0, UserDefaults.standard.integer(forKey: Keys.defaultBreakMinutes))
    }

    /// Neue Schichten übernehmen Lohn und Pause der letzten Schicht (Standard: an).
    static var useLastShiftAsTemplate: Bool {
        UserDefaults.standard.object(forKey: Keys.useLastShiftAsTemplate) as? Bool ?? true
    }

    /// Verdienst in der Live Activity auch bei gesperrtem Gerät aktualisieren (Standard: an).
    static var backgroundUpdatesEnabled: Bool {
        UserDefaults.standard.object(forKey: Keys.backgroundUpdatesEnabled) as? Bool ?? true
    }

    /// Lohn und Pause, mit denen eine neue Schicht vorbelegt wird.
    @MainActor static func newShiftDefaults(lastShift: Shift?) -> (hourlyWage: Double?, breakMinutes: Int) {
        if useLastShiftAsTemplate, let lastShift {
            return (lastShift.hourlyWage, lastShift.breakMinutes)
        }
        return (defaultHourlyWage, defaultBreakMinutes)
    }

    /// Symbol einer Währung in der Sprache des Geräts, z.B. "€" für "EUR".
    static func currencySymbol(for code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.currencySymbol ?? code
    }
}

extension Double {
    /// Betrag als Währung in der Schreibweise des Geräts, z.B. "14,00 €".
    func currency(_ code: String) -> String {
        formatted(.currency(code: code))
    }
}
