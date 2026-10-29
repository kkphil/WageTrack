import SwiftUI
import SwiftData

struct AddShiftView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Shift.date, order: .reverse) private var shifts: [Shift]
    
    @State private var date = Date()
    @State private var start = Date().addingTimeInterval(-21600)
    @State private var end = Date()
    @State private var breakMin = 0
    @State private var wage = 14.0
    @State private var tip = 0.0
    @State private var isArchived = false
    @State private var showingDiscardConfirmation = false

    /// Speichert eine gestoppte Live-Schicht: Abbrechen verwirft sie, daher wird nachgefragt.
    private let isLiveShift: Bool
    
    // NEU: Eigener Initializer, um übergebene Zeiten aufzunehmen
    init(initialStart: Date? = nil, initialEnd: Date? = nil, isLiveShift: Bool = false) {
        self.isLiveShift = isLiveShift
        // Wenn Zeiten übergeben werden (aus dem Live Tracker), nutzen wir diese.
        // Sonst nehmen wir die Standardwerte.
        let defaultStart = initialStart ?? Date().addingTimeInterval(-21600)
        let defaultEnd = initialEnd ?? Date()
        
        _date = State(initialValue: defaultStart)
        _start = State(initialValue: defaultStart)
        _end = State(initialValue: defaultEnd)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Zeit & Datum") {
                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                    DatePicker("Start", selection: $start, displayedComponents: .hourAndMinute)
                    DatePicker("Ende", selection: $end, displayedComponents: .hourAndMinute)
                    BreakPicker(minutes: $breakMin)
                }
                
                Section("Verdienst & Status") {
                    HStack {
                        Text("Stundenlohn (€)")
                        Spacer()
                        TextField("Lohn", value: $wage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Trinkgeld (€)")
                        Spacer()
                        TextField("Tip", value: $tip, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Toggle("Aus Berechnungen ausschließen", isOn: $isArchived)
                }
            }
            .navigationTitle("Neue Schicht")
            .onAppear {
                if let lastShift = shifts.first {
                    wage = lastShift.hourlyWage
                    breakMin = lastShift.breakMinutes
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let newShift = Shift(date: date, startTime: start, endTime: end, breakMinutes: breakMin, hourlyWage: wage, tip: tip, isArchived: isArchived)
                        modelContext.insert(newShift)
                        
                        // Wichtig: Erst speichern, dann exportieren
                        do {
                            try modelContext.save()
                            // @Query ist hier noch nicht aktualisiert, daher frisch laden,
                            // damit die neue Schicht im Export enthalten ist
                            let descriptor = FetchDescriptor<Shift>(sortBy: [SortDescriptor(\.date, order: .reverse)])
                            let allShifts = (try? modelContext.fetch(descriptor)) ?? shifts + [newShift]
                            CSVManager.exportToCSV(shifts: allShifts)
                        } catch {
                            print("Fehler beim Speichern: \(error.localizedDescription)")
                        }
                        
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        if isLiveShift {
                            showingDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .confirmationDialog("Live-Schicht verwerfen?", isPresented: $showingDiscardConfirmation, titleVisibility: .visible) {
                        Button("Verwerfen", role: .destructive) { dismiss() }
                        Button("Zurück", role: .cancel) {}
                    } message: {
                        Text("Die aufgezeichnete Schicht wird nicht gespeichert.")
                    }
                }
            }
        }
    }
}
