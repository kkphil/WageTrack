//
//  EditShiftView.swift
//  WageTrack
//
//  Created by Philip Kurth on 10.03.26.
//

import Foundation
import SwiftUI
import SwiftData

struct EditShiftView: View {
    @Bindable var shift: Shift
    @Query private var allShifts: [Shift]
    
    var body: some View {
        Form {
            Section("Zeit & Datum") {
                DatePicker("Datum", selection: $shift.date, displayedComponents: .date)
                DatePicker("Start", selection: $shift.startTime, displayedComponents: .hourAndMinute)
                DatePicker("Ende", selection: $shift.endTime, displayedComponents: .hourAndMinute)
                BreakPicker(minutes: $shift.breakMinutes)
            }
            
            Section("Verdienst") {
                HStack {
                    Text("Stundenlohn (€)")
                    Spacer()
                    TextField("Lohn", value: $shift.hourlyWage, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Trinkgeld (€)")
                    Spacer()
                    TextField("Tip", value: $shift.tip, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section("Zusammenfassung & Status") {
                LabeledContent("Arbeitszeit", value: durationInTimeString(from: shift.startTime, to: shift.endTime) + " Std")
                LabeledContent("Netto", value: (shift.totalEarnings - shift.tip).formatted(.currency(code: "EUR")))
                LabeledContent("Gesamtverdienst", value: shift.totalEarnings.formatted(.currency(code: "EUR")))
                Toggle("Von Berechnungen ausschließen", isOn: $shift.isArchived) // NEU
            }
        }
        .navigationTitle("Bearbeiten")
        .onDisappear {
            CSVManager.exportToCSV(shifts: allShifts)
        }
    }
}
