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
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppSettings.Keys.currencyCode) private var currencyCode = AppSettings.systemCurrencyCode

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
                    Text("Stundenlohn (\(AppSettings.currencySymbol(for: currencyCode)))")
                    Spacer()
                    TextField("Lohn", value: $shift.hourlyWage, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Trinkgeld (\(AppSettings.currencySymbol(for: currencyCode)))")
                    Spacer()
                    TextField("Tip", value: $shift.tip, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Zusammenfassung & Status") {
                LabeledContent("Arbeitszeit", value: durationInTimeString(from: shift.startTime, to: shift.endTime, breakMinutes: shift.breakMinutes) + " Std")
                LabeledContent("Netto", value: shift.wageEarnings.currency(currencyCode))
                LabeledContent("Gesamtverdienst", value: shift.totalEarnings.currency(currencyCode))
                Toggle("Von Berechnungen ausschließen", isOn: $shift.isArchived)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Bearbeiten")
        .onDisappear {
            // Änderungen sofort sichern, statt auf das automatische Speichern zu warten
            try? modelContext.save()
            CSVManager.export(from: modelContext)
        }
    }
}
