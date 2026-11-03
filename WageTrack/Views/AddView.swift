import SwiftUI
import SwiftData

struct AddShiftView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Shift.date, order: .reverse) private var shifts: [Shift]
    @AppStorage(AppSettings.Keys.currencyCode) private var currencyCode = AppSettings.systemCurrencyCode

    @State private var date: Date
    @State private var start: Date
    @State private var end: Date
    @State private var breakMin = 0
    /// `nil`, solange das Feld leer ist
    @State private var wage: Double?
    @State private var tip: Double?
    @State private var isArchived = false
    @State private var didLoadDefaults = false
    @State private var showingDiscardConfirmation = false
    @State private var saveError: String?

    /// Speichert eine gestoppte Live-Schicht: Abbrechen verwirft sie, daher wird nachgefragt.
    private let isLiveShift: Bool
    /// Wird aufgerufen, sobald die Schicht gespeichert oder bewusst verworfen wurde.
    private let onFinish: () -> Void

    /// - Parameters:
    ///   - initialStart: Beginn der Schicht (Standard: `AppSettings.manualShiftDuration` vor jetzt).
    ///   - initialEnd: Ende der Schicht (Standard: jetzt).
    ///   - initialWage: Stundenlohn; ohne Angabe wird er aus den Einstellungen vorbelegt.
    init(initialStart: Date? = nil, initialEnd: Date? = nil, initialWage: Double? = nil, isLiveShift: Bool = false, onFinish: @escaping () -> Void = {}) {
        self.isLiveShift = isLiveShift
        self.onFinish = onFinish

        let end = initialEnd ?? Date()
        let start = initialStart ?? end.addingTimeInterval(-AppSettings.manualShiftDuration)
        _date = State(initialValue: start)
        _start = State(initialValue: start)
        _end = State(initialValue: end)
        _wage = State(initialValue: initialWage)
    }

    private var canSave: Bool {
        guard let wage else { return false }
        return wage.isFinite && wage >= 0 && (tip ?? 0) >= 0
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

                Section {
                    HStack {
                        Text("Stundenlohn (\(AppSettings.currencySymbol(for: currencyCode)))")
                        Spacer()
                        TextField("Lohn", value: $wage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Trinkgeld (\(AppSettings.currencySymbol(for: currencyCode)))")
                        Spacer()
                        TextField("0", value: $tip, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Toggle("Aus Berechnungen ausschließen", isOn: $isArchived)
                } header: {
                    Text("Verdienst & Status")
                } footer: {
                    if wage == nil {
                        Text("Trage einen Stundenlohn ein, um die Schicht zu speichern. Einen Standardwert kannst du in den Einstellungen festlegen.")
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Neue Schicht")
            .onAppear(perform: loadDefaults)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern", action: save)
                        .disabled(!canSave)
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
                        Button("Verwerfen", role: .destructive) {
                            onFinish()
                            dismiss()
                        }
                        Button("Zurück", role: .cancel) {}
                    } message: {
                        Text("Die aufgezeichnete Schicht wird nicht gespeichert.")
                    }
                }
            }
            .alert("Speichern fehlgeschlagen", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    /// Belegt Lohn und Pause einmalig vor (nicht bei jedem Erscheinen, das würde Eingaben überschreiben).
    private func loadDefaults() {
        guard !didLoadDefaults else { return }
        didLoadDefaults = true

        let defaults = AppSettings.newShiftDefaults(lastShift: shifts.first)
        breakMin = defaults.breakMinutes
        // Eine Live-Schicht bringt den Lohn mit, mit dem sie aufgezeichnet wurde
        if wage == nil {
            wage = defaults.hourlyWage
        }
    }

    private func save() {
        guard canSave, let wage else { return }

        let newShift = Shift(date: date, startTime: start, endTime: end, breakMinutes: breakMin, hourlyWage: wage, tip: tip ?? 0, isArchived: isArchived)
        modelContext.insert(newShift)

        do {
            try modelContext.save()
        } catch {
            // Das Formular bleibt offen, damit nichts verloren geht (vor allem keine Live-Schicht)
            modelContext.delete(newShift)
            saveError = error.localizedDescription
            return
        }

        CSVManager.export(from: modelContext)
        onFinish()
        dismiss()
    }
}
