import Foundation

public enum DashboardService {
    private static let supabaseURL = "https://ygtemljaowgiypcberhz.supabase.co"
    private static let supabaseAnonKey = "sb_publishable_od7WoRDYP46HKboEp2s1aA_HXWRf54X"

    public static func submit(
        anonymousName: String,
        todayMM: Double,
        totalMM: Double,
        bestDayMM: Double,
        daysTracked: Int,
        milestone: String?
    ) {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/entries") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "anonymous_name": anonymousName,
            "today_mm": Int64(todayMM),
            "total_mm": Int64(totalMM),
            "best_day_mm": Int64(bestDayMM),
            "days_tracked": daysTracked,
            "milestone": milestone as Any
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request).resume()
    }
}
