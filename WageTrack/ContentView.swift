import SwiftUI
import SwiftData


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Shift.date, order: .reverse) private var shifts: [Shift]
    
    @State private var showingAddSheet = false
    
    @State private var showingDeleteAlert = false
    @State private var shiftToDelete: Shift?
    
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
                HStack {
                    Text("Meine Schichten")
                        .padding(.leading)
                        .font(.largeTitle)
                        .bold()
                        .lineLimit(1)
                    Text("(\(shifts.count))")
                        .foregroundStyle(.gray)
                        .fontWeight(.semibold)
                        .font(.largeTitle)
                        .bold()
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
                
                List {
                    ForEach(groupedShifts, id: \.month) { group in
                        Section(header: Text(group.month)) {
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
                        }
                        shiftToDelete = nil
                    }
                } message: {
                    Text("Möchtest du diese Schicht wirklich löschen? Dieser Vorgang kann nicht rückgängig gemacht werden.")
                }
            }
            .toolbar {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Label("Hinzufügen", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddShiftView()
            }
        }
    }
    
    private var groupedShifts: [(month: String, shifts: [Shift])] {
        // Group shifts by their year and month
        let grouped = Dictionary(grouping: shifts) { shift -> Date in
            let components = Calendar.current.dateComponents([.year, .month], from: shift.date)
            return Calendar.current.date(from: components) ?? shift.date
        }
        
        // Sort the group keys (months) from newest to oldest
        let sortedKeys = grouped.keys.sorted(by: >)
        
        // Format the key into a String like "Januar 2026" with German month names
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "LLLL yyyy"
        
        return sortedKeys.map { key in
            // Sort the shifts within the month from newest to oldest
            let sortedShifts = grouped[key]!.sorted { $0.date > $1.date }
            return (formatter.string(from: key), sortedShifts)
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
