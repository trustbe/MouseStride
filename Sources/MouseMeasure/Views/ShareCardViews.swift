import SwiftUI

// MARK: - Shared Card Style

private let cardWidth: CGFloat = 600
private let cardHeight: CGFloat = 315

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

// MARK: - Daily Recap Card

struct DailyRecapCard: View {
    let todayMM: Double
    let formattedDistance: String
    let comparison: String
    let milestone: String?
    let date: String

    var body: some View {
        ZStack {
            CardBackground()

            VStack(spacing: 16) {
                Spacer()

                Text("Today's Run")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))

                Text(formattedDistance)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)

                Text("\"\(comparison)\"")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .italic()

                if let milestone = milestone {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Text(milestone)
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
            .padding(24)
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - All-Time Stats Card

struct AllTimeStatsCard: View {
    let totalFormatted: String
    let daysTracked: Int
    let bestDayFormatted: String
    let highestMilestone: String?

    var body: some View {
        ZStack {
            CardBackground()

            VStack(spacing: 16) {
                Spacer()

                Text("My MouseStride Stats")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))

                Text(totalFormatted)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)

                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(daysTracked)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text("Days")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    VStack(spacing: 4) {
                        Text(bestDayFormatted)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text("Best Day")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                if let milestone = highestMilestone {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Text(milestone)
                            .fontWeight(.medium)
                            .foregroundStyle(.yellow)
                    }
                    .font(.callout)
                }

                Spacer()

                HStack {
                    Spacer()
                    CardBranding()
                }
            }
            .padding(24)
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - Milestone Achievement Card

struct MilestoneCard: View {
    let title: String
    let message: String
    let totalFormatted: String
    let icon: String

    var body: some View {
        ZStack {
            CardBackground()

            VStack(spacing: 16) {
                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.yellow)

                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text("Total: \(totalFormatted)")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                HStack {
                    Spacer()
                    CardBranding()
                }
            }
            .padding(24)
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}
