import Foundation

public enum ProviderStyle {
    public static func title(_ id: String) -> String {
        switch id {
        case "anthropic": "Anthropic"
        case "openai-codex": "Codex"
        case "openai": "OpenAI"
        case "kimi-code": "Kimi"
        case "xai-oauth", "xai": "xAI"
        case "google", "google-gemini-cli", "google-antigravity": "Gemini"
        case "github-copilot": "Copilot"
        case "cursor": "Cursor"
        case "openrouter": "OpenRouter"
        default:
            id.split(separator: "-")
                .map { part in
                    part.count <= 3 ? part.uppercased() : part.capitalized
                }
                .joined(separator: " ")
        }
    }

    public static func short(_ id: String) -> String {
        switch id {
        case "anthropic": "A"
        case "openai-codex": "C"
        case "openai": "O"
        case "kimi-code": "K"
        case "xai-oauth", "xai": "X"
        case "google", "google-gemini-cli", "google-antigravity": "G"
        case "github-copilot": "P"
        case "cursor": "R"
        default:
            String(title(id).prefix(1)).uppercased()
        }
    }
}

public enum Format {
    public static func remainingPercent(_ amount: LimitAmount) -> Int {
        Int((amount.remainingShare * 100).rounded())
    }

    public static func remainingPercent(_ share: Double) -> Int {
        Int((share * 100).rounded())
    }

    public static func age(_ date: Date, now: Date = Date()) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        if seconds < 10 { return "just now" }
        if seconds < 60 { return "\(Int(seconds))s ago" }
        if seconds < 3600 {
            return "\(Int(seconds / 60))m ago"
        }
        if seconds < 86_400 {
            let hours = Int(seconds / 3600)
            let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
            return minutes == 0 ? "\(hours)h ago" : "\(hours)h \(minutes)m ago"
        }
        let days = Int(seconds / 86_400)
        return days == 1 ? "1d ago" : "\(days)d ago"
    }

    public static func reset(_ date: Date, now: Date = Date()) -> String {
        let seconds = date.timeIntervalSince(now)
        if seconds <= 0 { return "now" }
        if seconds < 60 { return "\(max(1, Int(seconds)))s" }
        if seconds < 3600 { return "\(Int(seconds / 60))m" }
        if seconds < 86_400 {
            let hours = Int(seconds / 3600)
            let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
            return minutes == 0 ? "\(hours)h" : "\(hours)h\(minutes)m"
        }
        let days = Int(seconds / 86_400)
        let hours = Int(seconds.truncatingRemainder(dividingBy: 86_400) / 3600)
        return hours == 0 ? "\(days)d" : "\(days)d\(hours)h"
    }

    public static func accountLabel(_ metadata: ProviderMetadata?) -> String? {
        if let email = metadata?.email, !email.isEmpty { return email }
        if let accountId = metadata?.accountId, !accountId.isEmpty { return accountId }
        return nil
    }

    public static func tooltip(for snapshot: UsageSnapshot, now: Date = Date()) -> String {
        snapshot.groupedProviders.map { group in
            let bits = group.reports.flatMap(\.limits).map { limit in
                "\(limit.label) \(remainingPercent(limit.amount))%"
            }
            return "\(ProviderStyle.title(group.provider)): \(bits.joined(separator: " · "))"
        }
        .joined(separator: "\n")
    }
}
