import AppKit
import SwiftUI

struct PopupView: View {
    @ObservedObject var viewModel: MouseStrideViewModel
    @State private var isHoveringSync = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with dynamic tagline
            HStack(spacing: 8) {
                Image(systemName: "computermouse.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("MouseStride")
                            .font(.headline)
                        Text("(\(AnonymousNameService.name))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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

            // Launch at login
            HStack(spacing: 6) {
                Image(systemName: "sunrise")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text("Start with Mac")
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { LaunchAtLoginService.isEnabled },
                    set: { _ in LaunchAtLoginService.toggle() }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
            }

            // Community Sync toggle
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Button {
                        viewModel.submitToDashboard()
                        let name = AnonymousNameService.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "https://trustbe.github.io/MouseStride/?highlight=\(name)") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Text("Community Sync")
                            .underline(isHoveringSync)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                    .onHover { hovering in
                        isHoveringSync = hovering
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.autoShareEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }
                Text("Strictly anonymous · every 15 min")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 22)
            }

            Divider()

            // Actions
            HStack {
                Button("Share Results") {
                    ShareService.shareText(
                        todayFormatted: DistanceUnit.autoFormat(mm: viewModel.todayDistanceMM, system: viewModel.unitSystem),
                        totalFormatted: DistanceUnit.allTimeFormat(mm: viewModel.totalDistanceMM, system: viewModel.unitSystem),
                        daysTracked: viewModel.daysTracked,
                        bestDayFormatted: DistanceUnit.autoFormat(mm: viewModel.bestDayMM, system: viewModel.unitSystem),
                        milestone: viewModel.lastReachedMilestone,
                        todayMM: viewModel.todayDistanceMM,
                        totalMM: viewModel.totalDistanceMM,
                        bestDayMM: viewModel.bestDayMM
                    )
                }

                Spacer()

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
