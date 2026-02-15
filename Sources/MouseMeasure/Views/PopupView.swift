import AppKit
import SwiftUI

struct PopupView: View {
    @ObservedObject var viewModel: MouseMeasureViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with dynamic tagline
            HStack(spacing: 8) {
                Image(systemName: "computermouse.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("CursorFit")
                        .font(.headline)
                    Text(tagline(forMM: viewModel.totalDistanceMM))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Milestone badges
            if viewModel.lastMilestoneTitle != nil || viewModel.nextMilestoneText != nil {
                VStack(alignment: .leading, spacing: 3) {
                    if let last = viewModel.lastMilestoneTitle {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            Text(last)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    if let next = viewModel.nextMilestoneText {
                        HStack(spacing: 4) {
                            Image(systemName: "flag.checkered")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(next)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Divider()

            // Stats
            StatRow(label: "Today", value: DistanceUnit.autoFormat(mm: viewModel.todayDistanceMM, system: viewModel.unitSystem), icon: "calendar")
            StatRow(label: "All Time", value: DistanceUnit.allTimeFormat(mm: viewModel.totalDistanceMM, system: viewModel.unitSystem), icon: "infinity")

            Divider()

            // Unit system picker
            HStack(spacing: 6) {
                Image(systemName: "ruler")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text("Units")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $viewModel.unitSystem) {
                    Text("Metric").tag(UnitSystem.metric)
                    Text("Imperial").tag(UnitSystem.imperial)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            Divider()

            // Actions
            HStack {
                Menu("Reset...") {
                    Button("Reset Today") {
                        confirmAndRun(
                            title: "Reset Today?",
                            message: "Today's progress will vanish. Your mouse won't remember any of this.",
                            action: viewModel.resetToday
                        )
                    }
                    Divider()
                    Button("Reset All") {
                        confirmAndRun(
                            title: "Reset Everything?",
                            message: "Every millimeter. Every kilometer. All gone forever. Your mouse will have an existential crisis.",
                            destructiveLabel: "Delete All Data",
                            action: viewModel.resetAll
                        )
                    }
                }

                Spacer()

                Button("Quit") {
                    confirmAndRun(
                        title: "Quit CursorFit?",
                        message: "Don't worry, your mouse's lifetime achievements are saved.",
                        destructiveLabel: "Quit",
                        action: viewModel.quit
                    )
                }
            }
        }
        .padding()
        .frame(width: 280)
    }

    private func confirmAndRun(
        title: String,
        message: String,
        destructiveLabel: String = "Reset",
        action: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: destructiveLabel)
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            action()
        }
    }

    private func tagline(forMM mm: Double) -> String {
        switch mm {
        case ..<1:
            return "Waiting for first moves..."
        case ..<100:        // < 10 cm
            return "Baby steps!"
        case ..<1_000:      // < 1 m
            return "Warming up the wrist"
        case ..<10_000:     // < 10 m
            return "Getting into the groove"
        case ..<100_000:    // < 100 m
            return "Your cursor is doing laps"
        case ..<1_000_000:  // < 1 km
            return "Training for a marathon"
        case ..<5_000_000:  // < 5 km
            return "Your cursor runs marathons!"
        case ..<10_000_000: // < 10 km
            return "Ultramarathon cursor!"
        case ..<42_195_000: // < 42.195 km
            return "Your cursor needs new shoes"
        case ..<100_000_000: // < 100 km
            return "Marathon completed!"
        default:
            return "Your cursor has seen the world"
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var icon: String = ""

    var body: some View {
        HStack(spacing: 6) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
            }
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
                .fontWeight(.medium)
        }
    }
}
