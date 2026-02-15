import Foundation

enum DashboardService {
    private static let supabaseURL = "https://REPLACE_ME.supabase.co"
    private static let supabaseAnonKey = "REPLACE_ME"

    static func submit(
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
            "anonymous_name": AnonymousNameService.name,
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
