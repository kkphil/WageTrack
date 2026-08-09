import SwiftUI
import SwiftData


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Shift.date, order: .reverse) private var shifts: [Shift]
    
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0){
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
                    ForEach(shifts) { shift in
                        ListEntryView(shift: shift)
                            .listRowBackground(Color(.secondarySystemBackground))
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(shifts[index])
                        }
                    }
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
}


extension Date {
    func format(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
