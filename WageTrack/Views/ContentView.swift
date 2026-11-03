import SwiftUI
import SwiftData


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Shift.date, order: .reverse) private var shifts: [Shift]

    @AppStorage(AppSettings.Keys.currencyCode) private var currencyCode = AppSettings.systemCurrencyCode

    @State private var addSheet: AddSheetContext?
    @State private var showingSettings = false
    @State private var showingMissingWageAlert = false

    @State private var showingDeleteAlert = false
    @State private var shiftToDelete: Shift?

    let liveManager: LiveShiftManager

    /// Zeiten, mit denen das Hinzufügen-Sheet vorbelegt wird (nil = Standardwerte).
    private struct AddSheetContext: Identifiable {
        let id = UUID()
        var start: Date?
        var end: Date?
        var hourlyWage: Double?
        /// Das Sheet speichert eine gestoppte Live-Schicht
        var isLiveShift = false
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0){
                Text("Zusammenfassung")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                SummaryView()
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                LiveInfoView(liveManager: liveManager)
                    .padding(.horizontal)
                    .padding(.bottom, 25)
                VStack(alignment: .leading) {
                    Text("Meine Schichten")
                        .padding(.leading)
                        .font(.largeTitle)
                        .bold()
                        .lineLimit(1)
                    
                    Text("(\(shifts.count)) • \(totalHoursFormatted)")
                        .padding(.leading)
                        .foregroundStyle(.gray)
                        .fontWeight(.medium)
                        .font(.default)
                        .bold()
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
                
                List {
                    ForEach(groupedShifts, id: \.month) { group in
                        Section(header: Text(headerText(for: group))
                        ) {
                            ForEach(group.shifts) { shift in
                                NavigationLink(destination: EditShiftView(shift: shift)) {
                                    ListEntryView(shift: shift)
                                }
                                .listRowBackground(Color(.secondarySystemBackground))
                            }
                            .onDelete { offsets in
                                if let index = offsets.first {
                                    shiftToDelete = group.shifts[index]
                                    showingDeleteAlert = true
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(SidebarListStyle())
                .alert("Schicht löschen", isPresented: $showingDeleteAlert) {
                    Button("Abbrechen", role: .cancel) {
                        shiftToDelete = nil // Bricht den Vorgang ab
                    }
                    Button("Löschen", role: .destructive) {
                        // Wenn der User bestätigt, löschen wir den gemerkten Eintrag
                        if let shift = shiftToDelete {
                            modelContext.delete(shift)
                            try? modelContext.save()
                            CSVManager.export(from: modelContext)
                        }
                        shiftToDelete = nil
                    }
                } message: {
                    Text("Möchtest du diese Schicht wirklich löschen? Dieser Vorgang kann nicht rückgängig gemacht werden.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Einstellungen", systemImage: "gearshape")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: {
                        // Eine laufende Live-Schicht bleibt beim manuellen Hinzufügen unberührt
                        addSheet = AddSheetContext()
                    }) {
                        Label("Hinzufügen", systemImage: "plus")
                    }
                    Button(action: toggleLiveShift) {
                        if liveManager.isTracking {
                            Image(systemName: "stop.fill")
                                .foregroundStyle(.red)
                                .accessibilityLabel("Stoppen")
                                .symbolEffect(.wiggle.byLayer.right, options: .repeat(.periodic(delay: 2)))
                        } else {
                            Label("Starten", systemImage: "clock.badge")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.red, Color.accentColor, .clear)
                        }
                    }
                }
            }
            .sheet(item: $addSheet, onDismiss: {
                // Sicherheitsnetz: Wurde das Sheet geschlossen, ohne dass die gestoppte Schicht
                // gespeichert oder verworfen wurde, wird sie erneut angeboten statt gelöscht
                presentPendingShift()
            }) { context in
                AddShiftView(
                    initialStart: context.start,
                    initialEnd: context.end,
                    initialWage: context.hourlyWage,
                    isLiveShift: context.isLiveShift,
                    onFinish: {
                        // Die gestoppte Live-Schicht ist erst jetzt erledigt (gespeichert oder verworfen)
                        if context.isLiveShift {
                            liveManager.reset()
                        }
                    }
                )
                // Wegwischen würde die gestoppte Schicht kommentarlos verwerfen
                .interactiveDismissDisabled(context.isLiveShift)
            }
            .sheet(isPresented: $showingSettings, onDismiss: {
                // Währung oder Hintergrund-Aktualisierung können sich geändert haben
                liveManager.settingsDidChange()
            }) {
                SettingsView()
            }
            .alert("Stundenlohn fehlt", isPresented: $showingMissingWageAlert) {
                Button("Einstellungen") { showingSettings = true }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Lege in den Einstellungen deinen Stundenlohn fest, um eine Schicht live aufzuzeichnen.")
            }
            .onAppear {
                // Wurde die App beendet, nachdem gestoppt aber bevor gespeichert wurde
                presentPendingShift()
            }
            .onChange(of: scenePhase, initial: true) { oldPhase, phase in
                switch phase {
                case .active: liveManager.appDidBecomeActive()
                // Beim Start meldet SwiftUI zuerst "background", da gibt es noch nichts abzuschließen
                case .background where oldPhase != .background: liveManager.appDidEnterBackground()
                default: break
                }
            }
        }
    }

    private func toggleLiveShift() {
        if liveManager.isTracking {
            liveManager.stopShift()
            presentPendingShift()
            return
        }
        // Eine gestoppte Schicht muss erst gespeichert oder verworfen werden
        guard !liveManager.hasPendingShift else {
            presentPendingShift()
            return
        }
        guard let wage = AppSettings.newShiftDefaults(lastShift: shifts.first).hourlyWage else {
            showingMissingWageAlert = true
            return
        }
        liveManager.startShift(hourlyWage: wage)
    }

    private func presentPendingShift() {
        // Nicht erneut öffnen, wenn das Sheet für die Schicht schon angezeigt wird
        guard liveManager.hasPendingShift, addSheet?.isLiveShift != true else { return }
        addSheet = AddSheetContext(
            start: liveManager.startTime,
            end: liveManager.endTime,
            hourlyWage: liveManager.hourlyWage,
            isLiveShift: true
        )
    }
    
    private var groupedShifts: [(month: String, shifts: [Shift])] {
        // Group shifts by their year and month
        let grouped = Dictionary(grouping: shifts) { shift -> Date in
            let components = Calendar.current.dateComponents([.year, .month], from: shift.date)
            return Calendar.current.date(from: components) ?? shift.date
        }
        
        // Sort the group keys (months) from newest to oldest
        let sortedKeys = grouped.keys.sorted(by: >)
        
        return sortedKeys.map { key in
            // Sort the shifts within the month from newest to oldest
            let sortedShifts = (grouped[key] ?? []).sorted { $0.date > $1.date }
            // Month name in the device language, e.g. "Januar 2026"
            return (key.formatted(.dateTime.month(.wide).year()), sortedShifts)
        }
    }
    
    private func headerText(for group: (month: String, shifts: [Shift])) -> String {
        let tot = group.shifts.reduce(0) { $0 + $1.totalEarnings }
        let tip = group.shifts.reduce(0) { $0 + $1.tip }
        let f = { (v: Double) in v.currency(currencyCode) }
        return "\(group.month) - \(f(tot))\n\(f(tot - tip)) • \(f(tip))"
    }
    
    private var totalHours: Double {
        shifts.filter { !$0.isArchived }
            .reduce(0) { $0 + $1.workedHours }
    }

    private var totalHoursFormatted: String {
        let hours = Int(totalHours)
        let minutes = Int(round((totalHours - Double(hours)) * 60))
        
        // Verhindert Anzeige von "25:60h" durch Rundung, macht stattdessen "26:00h" daraus
        if minutes == 60 {
            return String(format: "%d:00h", hours + 1)
        } else {
            return String(format: "%d:%02dh", hours, minutes)
        }
    }

}


extension Date {
    func format(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
