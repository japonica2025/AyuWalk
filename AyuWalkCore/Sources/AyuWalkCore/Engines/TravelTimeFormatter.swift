public enum TravelTimeFormatter {
    public static func routeSegmentText(minutes: Int) -> String {
        let normalizedMinutes = max(minutes, 1)
        let hours = normalizedMinutes / 60
        let remainingMinutes = normalizedMinutes % 60

        if hours == 0 {
            return "移动约 \(normalizedMinutes) 分钟"
        }

        if remainingMinutes == 0 {
            return "移动约 \(hours) 小时"
        }

        return "移动约 \(hours) 小时 \(remainingMinutes) 分钟"
    }
}
