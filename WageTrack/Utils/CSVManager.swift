import Foundation
import os
import SwiftData

/// Schreibt alle Schichten als CSV in den Dokumente-Ordner der App (in der Dateien-App
/// sichtbar). Dient als Sicherung und wird nach jeder Änderung aktualisiert.
struct CSVManager {
    nonisolated private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WageTrack", category: "CSV")

    /// Lädt alle Schichten frisch aus dem Kontext und exportiert sie.
    static func export(from context: ModelContext) {
        let descriptor = FetchDescriptor<Shift>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        do {
            exportToCSV(shifts: try context.fetch(descriptor))
        } catch {
            logger.error("Schichten konnten nicht geladen werden: \(error.localizedDescription, privacy: .public)")
        }
    }

    @discardableResult
    static func exportToCSV(shifts: [Shift]) -> URL? {
        var csvString = "Datum;Startzeit;Endzeit;Pause(Min);Stundenlohn;Trinkgeld;Gesamtverdienst;Archiviert\n"

        // Feste Schreibweise, unabhängig von Sprache und 12/24-Stunden-Einstellung des Geräts
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "dd.MM.yyyy"

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm"

        for shift in shifts {
            let fields = [
                dateFormatter.string(from: shift.date),
                timeFormatter.string(from: shift.startTime),
                timeFormatter.string(from: shift.endTime),
                String(shift.breakMinutes),
                amount(shift.hourlyWage),
                amount(shift.tip),
                amount(shift.totalEarnings),
                shift.isArchived ? "Ja" : "Nein",
            ]
            csvString.append(fields.joined(separator: ";") + "\n")
        }

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("Dokumente-Ordner nicht gefunden")
            return nil
        }
        let fileURL = documentsDirectory.appendingPathComponent("Schichtaufzeichnungen_\(dateFormatter.string(from: Date())).csv")

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            logger.info("CSV gespeichert: \(fileURL.lastPathComponent, privacy: .public)")
            return fileURL
        } catch {
            logger.error("Fehler beim Speichern der CSV: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private static func amount(_ value: Double) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}
