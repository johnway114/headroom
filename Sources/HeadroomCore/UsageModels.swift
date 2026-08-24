import Foundation

public struct UsageSnapshot: Codable, Sendable, Hashable {
    public var generatedAt: Double
    public var reports: [ProviderReport]
    public var capacity: [String: [CapacityWindow]]?

    public var generatedDate: Date {
        Date(timeIntervalSince1970: generatedAt / 1000)
    }

    public static func decode(_ data: Data) throws -> UsageSnapshot {
        var payload = data
        if let start = payload.firstIndex(of: UInt8(ascii: "{")) {
            payload = payload.subdata(in: start..<payload.endIndex)
        }
        return try JSONDecoder().decode(UsageSnapshot.self, from: payload)
    }

    public var groupedProviders: [ProviderGroup] {
        var order: [String] = []
        var map: [String: [ProviderReport]] = [:]
        for report in reports {
            if map[report.provider] == nil {
                order.append(report.provider)
            }
            map[report.provider, default: []].append(report)
        }
        return order
            .compactMap { id -> ProviderGroup? in
                guard let reports = map[id] else { return nil }
                return ProviderGroup(provider: id, reports: reports)
            }
            .sorted { $0.minRemaining < $1.minRemaining }
    }

    public var tightest: (ProviderReport, UsageLimit)? {
        reports
            .flatMap { report in report.limits.map { (report, $0) } }
            .min { lhs, rhs in
                lhs.1.remainingShare < rhs.1.remainingShare
            }
    }
}

public struct ProviderGroup: Sendable, Hashable, Identifiable {
    public var id: String { provider }
    public var provider: String
    public var reports: [ProviderReport]

    public var minRemaining: Double {
        reports.flatMap(\.limits).map(\.remainingShare).min() ?? 1
    }

    public var showsAccountLabels: Bool {
        reports.count > 1
    }
}

public struct ProviderReport: Codable, Sendable, Hashable, Identifiable {
    public var provider: String
    public var fetchedAt: Double
    public var limits: [UsageLimit]
    public var resetCredits: ResetCredits?
    public var metadata: ProviderMetadata?

    public var id: String {
        let account = metadata?.accountId ?? metadata?.email ?? ""
        return "\(provider):\(account):\(fetchedAt)"
    }

    public var fetchedDate: Date {
        Date(timeIntervalSince1970: fetchedAt / 1000)
    }
}

public struct UsageLimit: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var label: String
    public var scope: LimitScope?
    public var window: LimitWindow?
    public var amount: LimitAmount
    public var status: String

    public var remainingShare: Double {
        amount.remainingShare
    }

    public var isExhausted: Bool {
        status == "exhausted" || remainingShare <= 0
    }

    public var resetsAt: Date? {
        window?.resetsDate
    }
}

public struct LimitScope: Codable, Sendable, Hashable {
    public var provider: String?
    public var accountId: String?
    public var tier: String?
    public var modelId: String?
    public var windowId: String?
    public var shared: Bool?
}

public struct LimitWindow: Codable, Sendable, Hashable {
    public var id: String?
    public var label: String?
    public var durationMs: Double?
    public var resetsAt: Double?

    public var resetsDate: Date? {
        resetsAt.map { Date(timeIntervalSince1970: $0 / 1000) }
    }
}

public struct LimitAmount: Codable, Sendable, Hashable {
    public var used: Double?
    public var limit: Double?
    public var remaining: Double?
    public var usedFraction: Double?
    public var remainingFraction: Double?
    public var unit: String?

    public init(
        used: Double? = nil,
        limit: Double? = nil,
        remaining: Double? = nil,
        usedFraction: Double? = nil,
        remainingFraction: Double? = nil,
        unit: String? = nil
    ) {
        self.used = used
        self.limit = limit
        self.remaining = remaining
        self.usedFraction = usedFraction
        self.remainingFraction = remainingFraction
        self.unit = unit
    }

    public var remainingShare: Double {
        if let remainingFraction {
            return remainingFraction
        }
        if let remaining, let limit, limit > 0 {
            return remaining / limit
        }
        if let usedFraction {
            return max(0, 1 - usedFraction)
        }
        return 1
    }
}

public struct ResetCredits: Codable, Sendable, Hashable {
    public var availableCount: Int?
    public var credits: [ResetCredit]?
}

public struct ResetCredit: Codable, Sendable, Hashable {
    public var grantedAt: String?
    public var expiresAt: String?
    public var status: String?
}

public struct ProviderMetadata: Codable, Sendable, Hashable {
    public var planType: String?
    public var allowed: Bool?
    public var limitReached: Bool?
    public var email: String?
    public var accountId: String?
    public var orgId: String?
    public var orgName: String?
    public var endpoint: String?
    public var source: String?
    public var billingKind: String?
}

public struct CapacityWindow: Codable, Sendable, Hashable {
    public var window: String
    public var durationMs: Double?
    public var accounts: Double?
    public var usedAccounts: Double?
    public var remainingAccounts: Double?
}
