import Foundation
import UserNotifications

struct Milestone {
    let distanceMM: Double
    let title: String
    let body: String
}

final class MilestoneService {
    private let defaults = UserDefaults.standard
    private let key = "lastMilestoneIndex"

    static let milestones: [Milestone] = [
        Milestone(distanceMM: 400_000,        // 400 m
                  title: "400m Hurdles!",
                  body: "Your only obstacles were the keyboard and that coffee mug."),
        Milestone(distanceMM: 800_000,        // 800 m
                  title: "800m!",
                  body: "Middle-distance champion of the desk. The crowd goes mild!"),
        Milestone(distanceMM: 1_609_344,      // 1 mile
                  title: "One Mile!",
                  body: "Your mouse is officially a jogger. Time for a tiny headband."),
        Milestone(distanceMM: 5_000_000,      // 5 km
                  title: "5K Complete!",
                  body: "Your mouse deserves a participation medal and a banana."),
        Milestone(distanceMM: 10_000_000,     // 10 km
                  title: "10K!",
                  body: "Your mouse is now a serious runner. Should we get it tiny shoes?"),
        Milestone(distanceMM: 21_097_500,     // half marathon
                  title: "Half Marathon!",
                  body: "21.1 km! Your mouse is halfway to eternal glory. Don't stop now!"),
        Milestone(distanceMM: 42_195_000,     // marathon
                  title: "MARATHON COMPLETE!",
                  body: "42.195 km! Your mouse needs new shoes, a massage, and a vacation."),
        Milestone(distanceMM: 100_000_000,    // 100 km
                  title: "100 km Ultramarathon!",
                  body: "Your mouse has officially left the city. Send a postcard!"),
        Milestone(distanceMM: 250_000_000,    // 250 km
                  title: "250 km!",
                  body: "Your mouse could've walked from Prague to Brno by now."),
        Milestone(distanceMM: 500_000_000,    // 500 km
                  title: "500 km!",
                  body: "Your mouse is an intercity traveler. Does it need a train ticket?"),
        Milestone(distanceMM: 1_000_000_000,  // 1000 km
                  title: "1,000 km!",
                  body: "Your mouse belongs in a museum. Or at least in the Hall of Fame."),
    ]

    private var lastMilestoneIndex: Int {
        get { defaults.integer(forKey: key) - 1 } // stored as 1-based so 0 means none
        set { defaults.set(newValue + 1, forKey: key) }
    }

    init() {
        requestPermission()
    }

    func checkMilestones(totalMM: Double) {
        let current = lastMilestoneIndex
        for (index, milestone) in Self.milestones.enumerated() {
            if index > current && totalMM >= milestone.distanceMM {
                sendNotification(milestone: milestone)
                lastMilestoneIndex = index
            }
        }
    }

    func lastReachedMilestone(totalMM: Double) -> Milestone? {
        var last: Milestone? = nil
        for milestone in Self.milestones {
            if totalMM >= milestone.distanceMM {
                last = milestone
            } else {
                break
            }
        }
        return last
    }

    func nextMilestone(totalMM: Double) -> Milestone? {
        Self.milestones.first { totalMM < $0.distanceMM }
    }

    func resetMilestones() {
        defaults.removeObject(forKey: key)
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(milestone: Milestone) {
        let content = UNMutableNotificationContent()
        content.title = milestone.title
        content.body = milestone.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "milestone-\(Int(milestone.distanceMM))",
            content: content,
            trigger: nil // deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
    }
}
