import SwiftUI

// MARK: - Shared Card Style

private let cardWidth: CGFloat = 600
private let cardHeight: CGFloat = 440

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

            VStack(spacing: 10) {
                Spacer()

                // Mouse character - centered, big
                MouseCharacter(milestone: milestone, size: 200)

                // Milestone title as hero (or today distance if no milestone)
                if let milestone = milestone {
                    HStack(spacing: 8) {
                        Image(systemName: milestone.icon)
                        Text(milestone.title.uppercased())
                        Image(systemName: milestone.icon)
                    }
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)

                    Text("Today: \(todayFormatted)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.green)
                } else {
                    Text("Today: \(todayFormatted)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                }

                Text("\"\(comparison)\"")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
                    .italic()

                // Compact stats row
                HStack(spacing: 6) {
                    Text(totalFormatted).fontWeight(.bold) +
                    Text(" All Time").foregroundColor(.white.opacity(0.5))
                    Text("·").foregroundStyle(.white.opacity(0.3))
                    Text("\(daysTracked)").fontWeight(.bold) +
                    Text(" Days").foregroundColor(.white.opacity(0.5))
                    Text("·").foregroundStyle(.white.opacity(0.3))
                    Text(bestDayFormatted).fontWeight(.bold) +
                    Text(" Best Day").foregroundColor(.white.opacity(0.5))
                }
                .font(.caption)
                .foregroundStyle(.white)

                Spacer()

                // Footer
                HStack {
                    Text(date)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    CardBranding()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}
