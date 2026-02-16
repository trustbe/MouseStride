import AppKit
import SwiftUI

@MainActor
enum ShareService {
    private static let dashboardURL = "https://trustbe.github.io/MouseStride"

    static func shareText(
        todayFormatted: String,
        totalFormatted: String,
        daysTracked: Int,
        bestDayFormatted: String,
        milestone: Milestone?,
        todayMM: Double,
        totalMM: Double,
        bestDayMM: Double
    ) {
        DashboardService.submit(
            todayMM: todayMM,
            totalMM: totalMM,
            bestDayMM: bestDayMM,
            daysTracked: daysTracked,
            milestone: milestone?.title
        )

        var lines: [String] = []

        if let m = milestone {
            lines.append("\(m.title) \u{1F3C6}")
            lines.append("")
        }

        lines.append("\u{1F5B1}\u{FE0F} My mouse traveled \(todayFormatted) today!")
        lines.append("\u{1F4CA} Total: \(totalFormatted) \u{00B7} \(daysTracked) \(daysTracked == 1 ? "day" : "days") \u{00B7} Best: \(bestDayFormatted)")
        lines.append("")
        lines.append("Track your mouse \u{2192} \(dashboardURL)")

        let text = lines.joined(separator: "\n")
        let picker = NSSharingServicePicker(items: [text])

        guard let contentView = NSApp.keyWindow?.contentView else { return }
        picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
    }
}
