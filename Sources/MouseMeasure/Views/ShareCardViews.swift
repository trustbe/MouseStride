import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Card Constants

private let cardWidth: CGFloat = 600
private let cardHeight: CGFloat = 460
private let downloadURL = "github.com/username/MouseStride"

// Warm palette — tinted darks, not cold grays
private let bgTop = Color(red: 0.06, green: 0.05, blue: 0.10)
private let bgBottom = Color(red: 0.10, green: 0.08, blue: 0.14)
private let warmWhite = Color(red: 0.95, green: 0.93, blue: 0.90)
private let mutedWarm = Color(red: 0.65, green: 0.60, blue: 0.55)
private let accentGold = Color(red: 1.0, green: 0.82, blue: 0.35)
private let accentGreen = Color(red: 0.4, green: 0.85, blue: 0.55)

// MARK: - Background

private struct CardBackground: View {
    let milestone: Milestone?

    var body: some View {
        ZStack {
            LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)

            // Warm radial glow behind the mouse area
            RadialGradient(
                colors: [glowColor.opacity(0.15), .clear],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 20,
                endRadius: 260
            )
        }
    }

    private var glowColor: Color {
        milestone != nil ? accentGold : accentGreen
    }
}

// MARK: - QR Code

private struct QRCodeView: View {
    let url: String
    let size: CGFloat

    var body: some View {
        if let image = generateQRCode(from: url) {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .frame(width: size, height: size)
        }
    }

    private func generateQRCode(from string: String) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data("https://\(string)".utf8)
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let rep = NSCIImageRep(ciImage: scaled)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
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
            CardBackground(milestone: milestone)

            VStack(spacing: 0) {
                // — Top: Mouse character with breathing room
                Spacer().frame(height: 24)

                MouseCharacter(milestone: milestone, size: 200)
                    .shadow(color: (milestone != nil ? accentGold : accentGreen).opacity(0.3), radius: 24, y: 8)

                Spacer().frame(height: 20)

                // — Middle: Achievement or distance hero
                if let milestone = milestone {
                    milestoneHero(milestone)
                    Spacer().frame(height: 6)
                    todayDistance(size: 20, weight: .medium)
                } else {
                    todayDistance(size: 28, weight: .bold)
                }

                Spacer().frame(height: 8)

                Text("\u{201C}\(comparison)\u{201D}")
                    .font(.system(size: 13))
                    .foregroundStyle(mutedWarm.opacity(0.7))
                    .italic()

                Spacer().frame(height: 14)

                // — Stats row
                statsRow

                Spacer()

                // — Footer
                footer
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Components

    @ViewBuilder
    private func milestoneHero(_ m: Milestone) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: m.icon)
                    .font(.system(size: 18))
                Text(m.title.uppercased())
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                Image(systemName: m.icon)
                    .font(.system(size: 18))
            }
            .foregroundStyle(accentGold)

            // Thin decorative rule
            Rectangle()
                .fill(accentGold.opacity(0.3))
                .frame(width: 120, height: 1)
        }
    }

    @ViewBuilder
    private func todayDistance(size: CGFloat, weight: Font.Weight) -> some View {
        HStack(spacing: 6) {
            Text(todayFormatted)
                .font(.system(size: size, weight: weight, design: .rounded))
            Text("today")
                .font(.system(size: size * 0.6, weight: .regular))
                .foregroundStyle(warmWhite.opacity(0.5))
        }
        .foregroundStyle(accentGreen)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: totalFormatted, label: "all time")
            dot
            statCell(value: "\(daysTracked)", label: "days")
            dot
            statCell(value: bestDayFormatted, label: "best day")
        }
        .padding(.horizontal, 40)
    }

    private func statCell(value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(warmWhite.opacity(0.85))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(mutedWarm.opacity(0.5))
        }
    }

    private var dot: some View {
        Text("\u{2009}\u{00B7}\u{2009}")
            .font(.system(size: 13))
            .foregroundStyle(mutedWarm.opacity(0.25))
    }

    private var footer: some View {
        HStack(alignment: .center, spacing: 10) {
            // Left: branding
            HStack(spacing: 5) {
                Image(systemName: "cursorarrow.motionlines")
                    .font(.system(size: 10))
                Text("MouseStride")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(mutedWarm.opacity(0.45))

            Text("\u{00B7}")
                .foregroundStyle(mutedWarm.opacity(0.2))
                .font(.system(size: 10))

            Text(date)
                .font(.system(size: 10))
                .foregroundStyle(mutedWarm.opacity(0.35))

            Spacer()

            // Right: URL + QR
            Text(downloadURL)
                .font(.system(size: 9))
                .foregroundStyle(mutedWarm.opacity(0.35))

            QRCodeView(url: downloadURL, size: 36)
                .opacity(0.7)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }
}
