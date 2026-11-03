//
//  SettingsView.swift
//  WageTrack
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppSettings.Keys.currencyCode) private var currencyCode = AppSettings.systemCurrencyCode
    @AppStorage(AppSettings.Keys.defaultHourlyWage) private var defaultHourlyWage: Double?
    @AppStorage(AppSettings.Keys.defaultBreakMinutes) private var defaultBreakMinutes = 0
    @AppStorage(AppSettings.Keys.useLastShiftAsTemplate) private var useLastShiftAsTemplate = true
    @AppStorage(AppSettings.Keys.backgroundUpdatesEnabled) private var backgroundUpdatesEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Währung", selection: $currencyCode) {
                        ForEach(Self.currencies, id: \.code) { currency in
                            Text("\(currency.name) (\(currency.code))").tag(currency.code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } footer: {
                    Text("Beträge werden nur in dieser Währung angezeigt, nicht umgerechnet.")
                }

                Section {
                    HStack {
                        Text("Stundenlohn (\(AppSettings.currencySymbol(for: currencyCode)))")
                        Spacer()
                        TextField("Nicht festgelegt", value: $defaultHourlyWage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    BreakPicker(minutes: $defaultBreakMinutes)
                    Toggle("Letzte Schicht als Vorlage", isOn: $useLastShiftAsTemplate)
                } header: {
                    Text("Neue Schichten")
                } footer: {
                    Text(useLastShiftAsTemplate
                         ? "Neue Schichten übernehmen Stundenlohn und Pause der letzten Schicht. Die Werte oben gelten, solange es noch keine Schicht gibt."
                         : "Neue Schichten starten immer mit den Werten oben.")
                }

                Section {
                    Toggle("Bei gesperrtem iPhone aktualisieren", isOn: $backgroundUpdatesEnabled)
                } header: {
                    Text("Live-Tracking")
                } footer: {
                    Text("Hält die App während einer laufenden Schicht über den ungefähren Standort aktiv, damit der Verdienst in der Live-Aktivität weiterzählt. Der Standort wird weder gespeichert noch ausgewertet. Ohne diese Option zählt nur die Zeit weiter; der Verdienst wird beim Öffnen der App aktualisiert.")
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    /// Gängige Währungen mit ihrem Namen in der Sprache des Geräts, alphabetisch sortiert.
    private static let currencies: [(code: String, name: String)] = {
        var codes = Set(Locale.commonISOCurrencyCodes)
        // Die Währung der Region und eine früher gewählte müssen immer auswählbar bleiben
        codes.insert(AppSettings.systemCurrencyCode)
        codes.insert(AppSettings.currencyCode)
        return codes
            .map { (code: $0, name: Locale.current.localizedString(forCurrencyCode: $0) ?? $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()
}

#Preview {
    SettingsView()
}
