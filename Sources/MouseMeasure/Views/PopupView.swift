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
                    Text("MouseStride")
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
                            Image(systemName: viewModel.lastMilestoneIcon ?? "trophy.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            Text(last)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    if let next = viewModel.nextMilestoneText {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.nextMilestoneIcon ?? "flag.checkered")
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
                Button("Share") {
                    let card = ShareCard(
                        todayFormatted: DistanceUnit.autoFormat(mm: viewModel.todayDistanceMM, system: viewModel.unitSystem),
                        totalFormatted: DistanceUnit.allTimeFormat(mm: viewModel.totalDistanceMM, system: viewModel.unitSystem),
                        comparison: RealWorldComparison.compare(mm: viewModel.todayDistanceMM),
                        daysTracked: viewModel.daysTracked,
                        bestDayFormatted: DistanceUnit.autoFormat(mm: viewModel.bestDayMM, system: viewModel.unitSystem),
                        milestone: viewModel.lastReachedMilestone,
                        date: Self.todayDateString()
                    )
                    ShareService.shareImage(from: card)
                }

                Spacer()

                Button("Reset") {
                    confirmAndRun(
                        title: "Reset all data?",
                        message: "Every millimeter, every milestone - back to zero. Your mouse will have an existential crisis.",
                        destructiveLabel: "Delete All Data",
                        action: viewModel.resetAll
                    )
                }

                Button("Quit") {
                    confirmAndRun(
                        title: "Quit MouseStride?",
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

    private static func todayDateString() -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: Date())
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
            return "Your mouse is doing laps"
        case ..<1_000_000:  // < 1 km
            return "Training for a marathon"
        case ..<5_000_000:  // < 5 km
            return "Your mouse runs marathons!"
        case ..<10_000_000: // < 10 km
            return "Ultramarathon mouse!"
        case ..<42_195_000: // < 42.195 km
            return "Your mouse needs new shoes"
        case ..<100_000_000: // < 100 km
            return "Marathon completed!"
        default:
            return "Your mouse has seen the world"
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
