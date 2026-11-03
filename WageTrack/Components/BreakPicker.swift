//
//  BreakPicker.swift
//  WageTrack
//

import SwiftUI

/// Formularzeile zur Auswahl der Pause. Wie bei der Uhrzeit öffnet ein Tippen auf den Wert
/// ein Scroll-Rad, hier mit den Minuten von 0 bis 2 Stunden in 1-Minuten-Schritten.
struct BreakPicker: View {
    let title: String
    @Binding var minutes: Int

    @State private var showingWheel = false

    init(_ title: String = "Pause", minutes: Binding<Int>) {
        self.title = title
        _minutes = minutes
    }

    /// Ältere Schichten können längere Pausen haben; sie bleiben auswählbar, statt beim
    /// Öffnen des Rads stillschweigend gekürzt zu werden.
    private var selectableMinutes: ClosedRange<Int> {
        0...max(AppSettings.maxBreakMinutes, minutes)
    }

    var body: some View {
        LabeledContent(title) {
            Button {
                showingWheel = true
            } label: {
                Text("\(minutes) min")
                    .monospacedDigit()
                    .foregroundStyle(showingWheel ? Color.accentColor : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemFill), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue("\(minutes) Minuten")
            // Unter dem Wert aufklappen, wie das Rad der Uhrzeit
            .popover(isPresented: $showingWheel, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                Picker(title, selection: $minutes) {
                    ForEach(selectableMinutes, id: \.self) { minute in
                        Text("\(minute) min")
                            .monospacedDigit()
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(width: 200, height: 200)
                .padding(.horizontal, 8)
                // Auf dem iPhone würde das Popover sonst zu einem Sheet
                .presentationCompactAdaptation(.popover)
            }
        }
    }
}

#Preview {
    @Previewable @State var minutes = 30
    Form {
        BreakPicker(minutes: $minutes)
    }
}
