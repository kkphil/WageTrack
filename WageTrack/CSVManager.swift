import Foundation
import SwiftData

struct CSVManager {
    static func exportToCSV(shifts: [Shift]) {
        // 1. Header der CSV-Datei um "Archiviert" erweitert
        var csvString = "Datum;Startzeit;Endzeit;Pause(Min);Stundenlohn;Trinkgeld;Gesamtverdienst;Archiviert\n"
        
        // 2. Datenzeilen hinzufügen
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for shift in shifts {
            let archivedStr = shift.isArchived ? "Ja" : "Nein"
            let row = "\(dateFormatter.string(from: shift.date));" +
                      "\(timeFormatter.string(from: shift.startTime));" +
                      "\(timeFormatter.string(from: shift.endTime));" +
                      "\(shift.breakMinutes);" +
                      "\(shift.hourlyWage);" +
                      "\(shift.tip);" +
                      "\(String(format: "%.2f", shift.totalEarnings));" +
                      "\(archivedStr)\n"
            csvString.append(row)
        }
        
        // 3. Pfad zum Dokumenten-Ordner finden
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("Schichtaufzeichnungen_\(dateFormatter.string(from: Date())).csv")
            
            // 4. Datei schreiben
            do {
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                print("CSV gespeichert unter: \(fileURL.path)")
            } catch {
                print("Fehler beim Speichern der CSV: \(error)")
            }
        }
    }
}
