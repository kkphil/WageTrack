import ActivityKit
import WidgetKit
import SwiftUI

struct WageTrackLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ShiftActivityAttributes.self) { context in
            // Sperrbildschirm & Mitteilungszentrale UI (groß)
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Schicht läuft")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        elapsedText(for: context.attributes)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    // Live-Indikator
                    HStack(spacing: 3) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.red)
                        Text("Live")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }

                Divider()
                    .padding(.vertical, 2)

                // Verdienst-Anzeige
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Verdienst")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        earningsText(for: context.state)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(context.isStale ? .secondary : .green)
                        // Nur wenn die App den Betrag länger nicht aktualisieren konnte
                        if context.isStale {
                            Text("Stand \(context.state.updatedAt, style: .time)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Stundenlohn")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(context.attributes.hourlyWage, specifier: "%.2f") €/h")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }

                // Hinweis zum Beenden
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    Text("Öffne die App und tippe auf 'Stoppen' zum Beenden")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Erweiterte Ansicht (wenn man auf die Dynamic Island tippt)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.red)
                            Text("Live")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        Text("Arbeit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 8)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        elapsedText(for: context.attributes)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        earningsText(for: context.state)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(context.isStale ? .secondary : .green)
                    }
                    .multilineTextAlignment(.trailing)
                    .padding(.trailing, 8)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        if context.isStale {
                            Text("Verdienst Stand \(context.state.updatedAt, style: .time)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Öffne die App zum Beenden")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                // Kompakte Ansicht links (kleines Icon)
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                // Kompakte Ansicht rechts: unter 1 Std. "MM:SS", ab 1 Std. nur noch "H:MM".
                // maxFieldCount: 2 sorgt dafür, dass das System die Sekunden automatisch weglässt.
                Text(.currentDate, format: .timer(
                    countingUpIn: elapsedRange(for: context.attributes),
                    maxFieldCount: 2
                ))
                // Timer-Texte reservieren sonst Platz für den längsten möglichen Wert und machen
                // die Dynamic Island unnötig breit. "45:30" bzw. "7:45" passen in 42 pt.
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                .foregroundColor(.blue)
                .multilineTextAlignment(.trailing)
                .frame(width: 42, alignment: .trailing)
            } minimal: {
                // Minimale Ansicht (nur Icon wenn mehrere Activities aktiv sind)
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.blue)
            }
        }
    }

    // Zeitbereich für den hochzählenden Timer. Live Activities laufen max. 8 Std. (danach
    // startet die App eine neue), 24 Std. sind daher großzügig bemessen.
    private func elapsedRange(for attributes: ShiftActivityAttributes) -> Range<Date> {
        attributes.startTime..<attributes.startTime.addingTimeInterval(86_400)
    }

    // Vom System animierter Timer (H:MM:SS) – läuft ohne Updates durch die App weiter
    private func elapsedText(for attributes: ShiftActivityAttributes) -> Text {
        Text(.currentDate, format: .timer(countingUpIn: elapsedRange(for: attributes)))
    }

    // Verdienst kommt aus dem ContentState: Eigene Berechnungen (auch eigene FormatStyles)
    // kann das System beim Rendern der Live Activity nicht ausführen, nur seine Timer-Formate.
    private func earningsText(for state: ShiftActivityAttributes.ContentState) -> some View {
        Text("\(state.earnings, specifier: "%.2f") €")
            .contentTransition(.numericText(value: state.earnings))
    }
}
