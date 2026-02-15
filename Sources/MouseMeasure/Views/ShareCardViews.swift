import SwiftUI

// MARK: - Shared Card Style

private let cardWidth: CGFloat = 600
private let cardHeight: CGFloat = 400

private struct CardBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.12, green: 0.12, blue: 0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct CardBranding: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "cursorarrow.motionlines")
                .font(.caption)
            Text("MouseStride")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white.opacity(0.5))
    }
}

// MARK: - Unified Share Card

struct ShareCard: View {
    let todayFormatted: String
    let totalFormatted: String
    let comparison: String
    let daysTracked: Int
    let bestDayFormatted: String
    let milestone: Milestone?
    let date: String

    var body: some View {
        ZStack {
            CardBackground()

            HStack(spacing: 20) {
                // Mouse character - left side
                MouseCharacter(milestone: milestone, size: 120)
                    .padding(.leading, 16)

                // Stats - right side
                VStack(spacing: 12) {
                    Spacer()

                    // Today's distance - hero number
                    Text("Today: \(todayFormatted)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)

                    Text("\"\(comparison)\"")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                        .italic()

                    // All-time stats row
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text(totalFormatted)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Text("All Time")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        VStack(spacing: 4) {
                            Text("\(daysTracked)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Text("Days")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        VStack(spacing: 4) {
                            Text(bestDayFormatted)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Text("Best Day")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }

                    // Milestone badge
                    if let milestone = milestone {
                        HStack(spacing: 6) {
                            Image(systemName: milestone.icon)
                                .foregroundStyle(.yellow)
                            Text(milestone.title)
                                .fontWeight(.medium)
                                .foregroundStyle(.yellow)
                        }
                        .font(.callout)
                    }

                    Spacer()

                    HStack {
                        Text(date)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                        CardBranding()
                    }
                }
                .padding(.trailing, 24)
                .padding(.vertical, 20)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}
