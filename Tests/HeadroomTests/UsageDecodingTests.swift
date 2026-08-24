import Foundation
import HeadroomCore
import Testing

struct UsageDecodingTests {
    @Test func decodesLiveFixture() throws {
        let url = try #require(Bundle.module.url(forResource: "fixture", withExtension: "json"))
        let snapshot = try UsageSnapshot.decode(Data(contentsOf: url))

        #expect(snapshot.reports.count == 4)
        #expect(snapshot.tightest?.0.provider == "anthropic")
        #expect(snapshot.tightest?.1.id == "anthropic:7d")
        #expect(snapshot.tightest?.1.isExhausted == true)

        let groups = snapshot.groupedProviders
        #expect(groups.first?.provider == "anthropic")
        #expect(groups.map(\.provider).sorted() == ["anthropic", "kimi-code", "openai-codex", "xai-oauth"].sorted())

        let fable = snapshot.reports
            .first { $0.provider == "anthropic" }?
            .limits.first { $0.id == "anthropic:7d:fable" }
        #expect(Format.remainingPercent(fable!.amount) == 66)

        let codex = snapshot.reports.first { $0.provider == "openai-codex" }
        #expect(codex?.resetCredits?.availableCount == 1)
        #expect(codex?.metadata?.planType == "pro")
    }

    @Test func ignoresPreambleBeforeJSON() throws {
        let raw = Data("warn: stale\n{\"generatedAt\":1,\"reports\":[]}".utf8)
        let snapshot = try UsageSnapshot.decode(raw)
        #expect(snapshot.reports.isEmpty)
        #expect(snapshot.generatedAt == 1)
    }
}

struct FormatTests {
    @Test func remainingRoundsFloatNoise() {
        var amount = LimitAmount(
            used: 34,
            limit: 100,
            remaining: 66,
            usedFraction: 0.34,
            remainingFraction: 0.6599999999999999,
            unit: "percent"
        )
        #expect(Format.remainingPercent(amount) == 66)

        amount.remainingFraction = nil
        amount.remaining = 46
        amount.limit = 100
        #expect(Format.remainingPercent(amount) == 46)
    }

    @Test func resetCompactsWindows() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        #expect(Format.reset(now.addingTimeInterval(45), now: now) == "45s")
        #expect(Format.reset(now.addingTimeInterval(12 * 60), now: now) == "12m")
        #expect(Format.reset(now.addingTimeInterval(8 * 3600 + 14 * 60), now: now) == "8h14m")
        #expect(Format.reset(now.addingTimeInterval(2 * 86_400 + 3 * 3600), now: now) == "2d3h")
    }

    @Test func providerTitles() {
        #expect(ProviderStyle.title("openai-codex") == "Codex")
        #expect(ProviderStyle.short("anthropic") == "A")
        #expect(ProviderStyle.short("kimi-code") == "K")
    }
}
