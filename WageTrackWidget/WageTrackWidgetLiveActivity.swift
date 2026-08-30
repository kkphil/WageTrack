import ActivityKit
import WidgetKit
import SwiftUI

struct WageTrackLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ShiftActivityAttributes.self) { context in
            // Sperrbildschirm UI
            HStack {
                VStack(alignment: .leading) {
                    Text("Schicht läuft")
                        .font(.headline)
                    Text(timerInterval: context.attributes.startTime...Date().addingTimeInterval(86400), countsDown: false)
                        .font(.title2).bold()
                        .foregroundColor(.blue)
                }
                Spacer()
                Image(systemName: "briefcase.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
            .padding()
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Arbeit")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.attributes.startTime...Date().addingTimeInterval(86400), countsDown: false)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Öffne die App zum Beenden")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } compactLeading: {
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                // HIER ANGEPASST: Nutzt den nativen, tickenden Timer.
                // Mit monospacedDigit() springen die Zahlen beim Ticken nicht hin und her.
                Text(timerInterval: context.attributes.startTime...Date().addingTimeInterval(86400), countsDown: false)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.blue)
                    .frame(maxWidth: 55) // Etwas mehr Platz für die Sekunden
            } minimal: {
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}
