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

    var body: some View {
        NavigationStack {
            Form {
                Section("Zeit & Datum") {
                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                    DatePicker("Start", selection: $start, displayedComponents: .hourAndMinute)
                    DatePicker("Ende", selection: $end, displayedComponents: .hourAndMinute)
                    HStack {
                        Text("Pause")
                        Spacer()
                        Picker("(min)", selection: $breakMin){
                            ForEach(Array(stride(from: 0, through: 180, by: 5)).map { Int($0) }, id: \.self) { minute in
                                let hours = minute / 60
                                let minutes = minute % 60
                                Text(String(format: "%02d:%02d (Std.)", hours, minutes))
                                    .tag(minute)
                            }
                        }.pickerStyle(.menu)
                    }
                }
                
                Section("Verdienst") {
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
                        let newShift = Shift(date: date, startTime: start, endTime: end, breakMinutes: breakMin, hourlyWage: wage, tip: tip)
                        modelContext.insert(newShift)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}
