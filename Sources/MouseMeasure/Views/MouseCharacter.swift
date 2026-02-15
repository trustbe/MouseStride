import SwiftUI

/// Cute cartoon mouse drawn with SwiftUI shapes, different pose per milestone
struct MouseCharacter: View {
    let milestone: Milestone?
    let size: CGFloat

    private var scale: CGFloat { size / 120 }

    var body: some View {
        ZStack {
            switch milestoneIndex {
            case nil:  standingMouse
            case 0:    sprintStartMouse
            case 1:    joggingMouse
            case 2:    headbandMouse
            case 3:    medalMouse
            case 4:    fastSprintMouse
            case 5:    sweatyMouse
            case 6:    victoryMouse
            case 7:    backpackMouse
            case 8:    trainMouse
            case 9:    capeMouse
            case 10:   globeMouse
            default:   standingMouse
            }
        }
        .frame(width: size, height: size)
    }

    private var milestoneIndex: Int? {
        guard let milestone = milestone else { return nil }
        return MilestoneService.milestones.firstIndex(where: { $0.distanceMM == milestone.distanceMM })
    }

    // MARK: - Base Mouse Parts

    private func mouseBody(at offset: CGPoint = .zero, rotation: Double = 0) -> some View {
        Ellipse()
            .fill(Color(red: 0.85, green: 0.85, blue: 0.88))
            .frame(width: 44 * scale, height: 38 * scale)
            .rotationEffect(.degrees(rotation))
            .offset(x: offset.x * scale, y: offset.y * scale)
    }

    private func mouseHead(at offset: CGPoint = .zero) -> some View {
        ZStack {
            // Head
            Circle()
                .fill(Color(red: 0.85, green: 0.85, blue: 0.88))
                .frame(width: 32 * scale, height: 32 * scale)

            // Left ear
            ZStack {
                Circle().fill(Color(red: 0.85, green: 0.85, blue: 0.88))
                    .frame(width: 18 * scale, height: 18 * scale)
                Circle().fill(Color(red: 0.95, green: 0.7, blue: 0.75))
                    .frame(width: 12 * scale, height: 12 * scale)
            }
            .offset(x: -14 * scale, y: -14 * scale)

            // Right ear
            ZStack {
                Circle().fill(Color(red: 0.85, green: 0.85, blue: 0.88))
                    .frame(width: 18 * scale, height: 18 * scale)
                Circle().fill(Color(red: 0.95, green: 0.7, blue: 0.75))
                    .frame(width: 12 * scale, height: 12 * scale)
            }
            .offset(x: 14 * scale, y: -14 * scale)

            // Eyes
            Circle().fill(.black)
                .frame(width: 5 * scale, height: 5 * scale)
                .offset(x: -6 * scale, y: -2 * scale)
            Circle().fill(.black)
                .frame(width: 5 * scale, height: 5 * scale)
                .offset(x: 6 * scale, y: -2 * scale)

            // Eye shine
            Circle().fill(.white)
                .frame(width: 2 * scale, height: 2 * scale)
                .offset(x: -5 * scale, y: -3 * scale)
            Circle().fill(.white)
                .frame(width: 2 * scale, height: 2 * scale)
                .offset(x: 7 * scale, y: -3 * scale)

            // Nose
            Circle().fill(Color(red: 0.95, green: 0.6, blue: 0.65))
                .frame(width: 5 * scale, height: 4 * scale)
                .offset(y: 5 * scale)

            // Smile
            Path { path in
                path.move(to: CGPoint(x: -4, y: 9))
                path.addQuadCurve(to: CGPoint(x: 4, y: 9), control: CGPoint(x: 0, y: 13))
            }
            .stroke(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 1.2 * scale)
            .frame(width: 10 * scale, height: 14 * scale)
            .scaleEffect(scale)
        }
        .offset(x: offset.x * scale, y: offset.y * scale)
    }

    private func leg(at offset: CGPoint, rotation: Double = 0) -> some View {
        Capsule()
            .fill(Color(red: 0.85, green: 0.85, blue: 0.88))
            .frame(width: 8 * scale, height: 16 * scale)
            .rotationEffect(.degrees(rotation), anchor: .top)
            .offset(x: offset.x * scale, y: offset.y * scale)
    }

    private func arm(at offset: CGPoint, rotation: Double = 0) -> some View {
        Capsule()
            .fill(Color(red: 0.85, green: 0.85, blue: 0.88))
            .frame(width: 6 * scale, height: 14 * scale)
            .rotationEffect(.degrees(rotation), anchor: .top)
            .offset(x: offset.x * scale, y: offset.y * scale)
    }

    private func tail(at offset: CGPoint = .zero) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addCurve(
                to: CGPoint(x: -20, y: -15),
                control1: CGPoint(x: -10, y: 5),
                control2: CGPoint(x: -25, y: -5)
            )
        }
        .stroke(Color(red: 0.8, green: 0.75, blue: 0.78), style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round))
        .frame(width: 30 * scale, height: 20 * scale)
        .offset(x: offset.x * scale, y: offset.y * scale)
    }

    private func shoe(at offset: CGPoint, rotation: Double = 0) -> some View {
        Capsule()
            .fill(Color(red: 0.2, green: 0.7, blue: 0.4))
            .frame(width: 12 * scale, height: 6 * scale)
            .rotationEffect(.degrees(rotation))
            .offset(x: offset.x * scale, y: offset.y * scale)
    }

    // MARK: - Accessories

    private var headband: some View {
        RoundedRectangle(cornerRadius: 2 * scale)
            .fill(Color(red: 0.2, green: 0.7, blue: 0.4))
            .frame(width: 34 * scale, height: 4 * scale)
    }

    private var medal: some View {
        ZStack {
            // Ribbon
            Path { path in
                path.move(to: CGPoint(x: -3, y: -8))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 3, y: -8))
            }
            .stroke(Color.red, lineWidth: 2 * scale)
            .frame(width: 8 * scale, height: 10 * scale)

            // Medal
            Circle().fill(.yellow)
                .frame(width: 10 * scale, height: 10 * scale)
            Circle().fill(Color.yellow.opacity(0.7))
                .frame(width: 6 * scale, height: 6 * scale)
        }
    }

    private func speedLines(at offset: CGPoint) -> some View {
        VStack(spacing: 4 * scale) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(.white.opacity(0.4))
                    .frame(width: CGFloat(12 - i * 3) * scale, height: 2 * scale)
            }
        }
        .offset(x: offset.x * scale, y: offset.y * scale)
    }

    private func sweatDrop(at offset: CGPoint) -> some View {
        Ellipse()
            .fill(Color(red: 0.5, green: 0.8, blue: 1.0))
            .frame(width: 4 * scale, height: 6 * scale)
            .offset(x: offset.x * scale, y: offset.y * scale)
    }

    // MARK: - Poses

    /// Standing still, looking forward
    private var standingMouse: some View {
        ZStack {
            tail(at: CGPoint(x: -20, y: 10))
            leg(at: CGPoint(x: -8, y: 18))
            leg(at: CGPoint(x: 8, y: 18))
            shoe(at: CGPoint(x: -8, y: 28))
            shoe(at: CGPoint(x: 8, y: 28))
            mouseBody()
            arm(at: CGPoint(x: -18, y: -2))
            arm(at: CGPoint(x: 18, y: -2))
            mouseHead(at: CGPoint(x: 0, y: -24))
        }
    }

    /// Sprint start - leaning forward
    private var sprintStartMouse: some View {
        ZStack {
            tail(at: CGPoint(x: -24, y: 4))
            leg(at: CGPoint(x: -6, y: 18), rotation: -20)
            leg(at: CGPoint(x: 10, y: 18), rotation: 15)
            shoe(at: CGPoint(x: -12, y: 26))
            shoe(at: CGPoint(x: 14, y: 28))
            mouseBody(rotation: -15)
            arm(at: CGPoint(x: -16, y: -4), rotation: -30)
            arm(at: CGPoint(x: 20, y: -2), rotation: 20)
            mouseHead(at: CGPoint(x: 4, y: -24))
        }
    }

    /// Casual jogging
    private var joggingMouse: some View {
        ZStack {
            tail(at: CGPoint(x: -22, y: 8))
            leg(at: CGPoint(x: -6, y: 18), rotation: -15)
            leg(at: CGPoint(x: 10, y: 18), rotation: 15)
            shoe(at: CGPoint(x: -10, y: 28))
            shoe(at: CGPoint(x: 14, y: 28))
            mouseBody(rotation: -8)
            arm(at: CGPoint(x: -18, y: -2), rotation: -20)
            arm(at: CGPoint(x: 18, y: -2), rotation: 20)
            mouseHead(at: CGPoint(x: 2, y: -24))
        }
    }

    /// Running with headband
    private var headbandMouse: some View {
        ZStack {
            tail(at: CGPoint(x: -22, y: 6))
            leg(at: CGPoint(x: -6, y: 18), rotation: -20)
            leg(at: CGPoint(x: 10, y: 18), rotation: 20)
            shoe(at: CGPoint(x: -12, y: 26))
            shoe(at: CGPoint(x: 16, y: 26))
            mouseBody(rotation: -10)
            arm(at: CGPoint(x: -18, y: -4), rotation: -25)
            arm(at: CGPoint(x: 18, y: -2), rotation: 25)
            mouseHead(at: CGPoint(x: 2, y: -24))
            headband.offset(x: 2 * scale, y: -28 * scale)
        }
    }

    /// Running with medal bouncing
    private var medalMouse: some View {
        ZStack {
            tail(at: CGPoint(x: -22, y: 6))
            leg(at: CGPoint(x: -6, y: 18), rotation: -20)
            leg(at: CGPoint(x: 10, y: 18), rotation: 20)
            shoe(at: CGPoint(x: -12, y: 26))
            shoe(at: CGPoint(x: 16, y: 26))
            mouseBody(rotation: -10)
            medal.offset(x: 4 * scale, y: 6 * scale)
            arm(at: CGPoint(x: -18, y: -4), rotation: -25)
            arm(at: CGPoint(x: 18, y: -2), rotation: 25)
            mouseHead(at: CGPoint(x: 2, y: -24))
            headband.offset(x: 2 * scale, y: -28 * scale)
        }
    }

    /// Fast sprint with speed lines
    private var fastSprintMouse: some View {
        ZStack {
            speedLines(at: CGPoint(x: -38, y: -10))
            speedLines(at: CGPoint(x: -35, y: 5))
            tail(at: CGPoint(x: -26, y: 2))
            leg(at: CGPoint(x: -4, y: 18), rotation: -30)
            leg(at: CGPoint(x: 14, y: 18), rotation: 25)
            shoe(at: CGPoint(x: -12, y: 24))
            shoe(at: CGPoint(x: 20, y: 26))
            mouseBody(rotation: -18)
            arm(at: CGPoint(x: -16, y: -6), rotation: -35)
            arm(at: CGPoint(x: 20, y: -4), rotation: 30)
            mouseHead(at: CGPoint(x: 6, y: -24))
            headband.offset(x: 6 * scale, y: -28 * scale)
        }
    }

    /// Determined running with sweat
    private var sweatyMouse: some View {
        ZStack {
            speedLines(at: CGPoint(x: -36, y: -8))
            tail(at: CGPoint(x: -24, y: 4))
            leg(at: CGPoint(x: -4, y: 18), rotation: -25)
            leg(at: CGPoint(x: 12, y: 18), rotation: 22)
            shoe(at: CGPoint(x: -12, y: 24))
            shoe(at: CGPoint(x: 18, y: 26))
            mouseBody(rotation: -14)
            arm(at: CGPoint(x: -16, y: -4), rotation: -30)
            arm(at: CGPoint(x: 20, y: -2), rotation: 28)
            mouseHead(at: CGPoint(x: 4, y: -24))
            headband.offset(x: 4 * scale, y: -28 * scale)
            sweatDrop(at: CGPoint(x: 18, y: -28))
            sweatDrop(at: CGPoint(x: -14, y: -20))
        }
    }

    /// Victory pose - arms up, crossing finish line
    private var victoryMouse: some View {
        ZStack {
            tail(at: CGPoint(x: -20, y: 10))
            leg(at: CGPoint(x: -8, y: 18))
            leg(at: CGPoint(x: 8, y: 18), rotation: 10)
            shoe(at: CGPoint(x: -8, y: 28))
            shoe(at: CGPoint(x: 12, y: 28))
            mouseBody()
            medal.offset(x: 0, y: 6 * scale)
            arm(at: CGPoint(x: -18, y: -8), rotation: -50)
            arm(at: CGPoint(x: 18, y: -8), rotation: 50)
            mouseHead(at: CGPoint(x: 0, y: -24))
            headband.offset(y: -28 * scale)
            // Star sparkles
            Image(systemName: "sparkle")
                .font(.system(size: 8 * scale))
                .foregroundStyle(.yellow)
                .offset(x: -24 * scale, y: -34 * scale)
            Image(systemName: "sparkle")
                .font(.system(size: 6 * scale))
                .foregroundStyle(.yellow)
                .offset(x: 26 * scale, y: -30 * scale)
        }
    }

    /// Adventurer with backpack
    private var backpackMouse: some View {
        ZStack {
            tail(at: CGPoint(x: -22, y: 8))
            // Backpack
            RoundedRectangle(cornerRadius: 4 * scale)
                .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                .frame(width: 16 * scale, height: 20 * scale)
                .offset(x: -8 * scale, y: -2 * scale)
            leg(at: CGPoint(x: -6, y: 18), rotation: -15)
            leg(at: CGPoint(x: 10, y: 18), rotation: 15)
            shoe(at: CGPoint(x: -10, y: 28))
            shoe(at: CGPoint(x: 14, y: 28))
            mouseBody(rotation: -8)
            arm(at: CGPoint(x: -18, y: -2), rotation: -15)
            arm(at: CGPoint(x: 18, y: -2), rotation: 15)
            mouseHead(at: CGPoint(x: 2, y: -24))
            headband.offset(x: 2 * scale, y: -28 * scale)
        }
    }

    /// Standing on a train
    private var trainMouse: some View {
        ZStack {
            // Train base
            RoundedRectangle(cornerRadius: 4 * scale)
                .fill(Color(red: 0.3, green: 0.5, blue: 0.7))
                .frame(width: 60 * scale, height: 14 * scale)
                .offset(y: 32 * scale)
            // Wheels
            Circle().fill(Color(red: 0.25, green: 0.25, blue: 0.3))
                .frame(width: 8 * scale, height: 8 * scale)
                .offset(x: -18 * scale, y: 38 * scale)
            Circle().fill(Color(red: 0.25, green: 0.25, blue: 0.3))
                .frame(width: 8 * scale, height: 8 * scale)
                .offset(x: 18 * scale, y: 38 * scale)
            // Mouse on top
            tail(at: CGPoint(x: -20, y: 4))
            leg(at: CGPoint(x: -8, y: 12))
            leg(at: CGPoint(x: 8, y: 12))
            mouseBody(at: CGPoint(x: 0, y: -6))
            arm(at: CGPoint(x: -18, y: -8), rotation: -10)
            arm(at: CGPoint(x: 18, y: -8), rotation: 10)
            mouseHead(at: CGPoint(x: 0, y: -30))
            headband.offset(y: -34 * scale)

            speedLines(at: CGPoint(x: -42, y: 30))
        }
    }

    /// Mouse with cape, flying pose
    private var capeMouse: some View {
        ZStack {
            // Cape
            Path { path in
                path.move(to: CGPoint(x: 0, y: -10))
                path.addCurve(
                    to: CGPoint(x: -30, y: 20),
                    control1: CGPoint(x: -5, y: 0),
                    control2: CGPoint(x: -35, y: 10)
                )
                path.addCurve(
                    to: CGPoint(x: -10, y: 10),
                    control1: CGPoint(x: -25, y: 25),
                    control2: CGPoint(x: -15, y: 15)
                )
                path.closeSubpath()
            }
            .fill(Color.red.opacity(0.8))
            .frame(width: 40 * scale, height: 30 * scale)
            .scaleEffect(scale)
            .offset(x: -6 * scale, y: 2 * scale)

            tail(at: CGPoint(x: -22, y: 6))
            leg(at: CGPoint(x: -6, y: 18), rotation: -10)
            leg(at: CGPoint(x: 10, y: 18), rotation: 10)
            shoe(at: CGPoint(x: -8, y: 28))
            shoe(at: CGPoint(x: 12, y: 28))
            mouseBody(rotation: -8)
            arm(at: CGPoint(x: -16, y: -6), rotation: -40)
            arm(at: CGPoint(x: 20, y: -6), rotation: 40)
            mouseHead(at: CGPoint(x: 2, y: -24))
            headband.offset(x: 2 * scale, y: -28 * scale)
        }
    }

    /// Standing proudly on top of a globe
    private var globeMouse: some View {
        ZStack {
            // Globe
            ZStack {
                Circle()
                    .fill(Color(red: 0.2, green: 0.5, blue: 0.8))
                    .frame(width: 50 * scale, height: 50 * scale)
                // Continent hint
                Ellipse()
                    .fill(Color(red: 0.3, green: 0.7, blue: 0.4))
                    .frame(width: 18 * scale, height: 22 * scale)
                    .offset(x: -4 * scale, y: -2 * scale)
                Ellipse()
                    .fill(Color(red: 0.3, green: 0.7, blue: 0.4))
                    .frame(width: 10 * scale, height: 14 * scale)
                    .offset(x: 12 * scale, y: 6 * scale)
            }
            .offset(y: 24 * scale)

            // Mouse on top of globe
            tail(at: CGPoint(x: -20, y: -4))
            leg(at: CGPoint(x: -8, y: 4))
            leg(at: CGPoint(x: 8, y: 4))
            shoe(at: CGPoint(x: -8, y: 14))
            shoe(at: CGPoint(x: 8, y: 14))
            mouseBody(at: CGPoint(x: 0, y: -14))
            medal.offset(x: 0, y: -8 * scale)
            arm(at: CGPoint(x: -18, y: -20), rotation: -50)
            arm(at: CGPoint(x: 18, y: -20), rotation: 50)
            mouseHead(at: CGPoint(x: 0, y: -38))
            headband.offset(y: -42 * scale)

            // Crown
            Image(systemName: "star.fill")
                .font(.system(size: 10 * scale))
                .foregroundStyle(.yellow)
                .offset(y: -54 * scale)
        }
    }
}
