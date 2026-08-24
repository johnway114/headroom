import AppKit
import HeadroomCore
import SwiftUI

struct UsagePopoverView: View {
    @Bindable var store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            content
            footer
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(width: 312)
        .fixedSize(horizontal: true, vertical: true)
        .background(Palette.paper)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Headroom")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text(statusCaption)
                .font(.system(size: 11))
                .foregroundStyle(Palette.mute)
                .monospacedDigit()
        }
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = store.snapshot {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(snapshot.groupedProviders) { group in
                    ProviderSection(
                        group: group,
                        now: store.clock
                    )
                }
            }
            if let error = store.error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.spent)
                    .padding(.top, 10)
            }
        } else if store.isRefreshing {
            Text("Fetching usage…")
                .font(.system(size: 12))
                .foregroundStyle(Palette.mute)
                .padding(.vertical, 18)
        } else if let error = store.error {
            Text(error)
                .font(.system(size: 12))
                .foregroundStyle(Palette.spent)
                .padding(.vertical, 18)
        } else {
            Text("No usage yet")
                .font(.system(size: 12))
                .foregroundStyle(Palette.mute)
                .padding(.vertical, 18)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button(store.isRefreshing ? "Refreshing" : "Refresh") {
                Task { await store.refresh(force: true) }
            }
            .disabled(store.isRefreshing)
            Spacer()
            if store.isBundled {
                Toggle("Open at login", isOn: loginBinding)
                    .toggleStyle(.checkbox)
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .buttonStyle(.plain)
        .font(.system(size: 11))
        .foregroundStyle(Palette.mute)
        .padding(.top, 12)
    }

    private var loginBinding: Binding<Bool> {
        Binding(
            get: { store.openAtLogin },
            set: { store.openAtLogin = $0 }
        )
    }

    private var statusCaption: String {
        if store.isRefreshing { return "updating" }
        if let snapshot = store.snapshot {
            return Format.age(snapshot.generatedDate, now: store.clock)
        }
        return ""
    }
}

private struct ProviderSection: View {
    let group: ProviderGroup
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(ProviderStyle.title(group.provider).uppercased())
                .font(.system(size: 10, weight: .semibold, design: .default))
                .tracking(0.8)
                .foregroundStyle(Palette.mute)

            ForEach(group.reports) { report in
                if group.showsAccountLabels, let label = Format.accountLabel(report.metadata) {
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.mute)
                        .padding(.top, 2)
                }
                ForEach(report.limits) { limit in
                    LimitRow(limit: limit, now: now)
                }
                if let count = report.resetCredits?.availableCount, count > 0 {
                    Text(count == 1 ? "1 saved reset" : "\(count) saved resets")
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.mute)
                }
            }
        }
    }
}

private struct LimitRow: View {
    let limit: UsageLimit
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(limit.label)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let reset = limit.resetsAt {
                    Text(Format.reset(reset, now: now))
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(Palette.mute)
                }
                Text("\(Format.remainingPercent(limit.amount))")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(limit.isExhausted ? Palette.spent : Palette.ink)
                    .frame(width: 28, alignment: .trailing)
            }
            RemainingBar(share: limit.remainingShare, spent: limit.isExhausted)
        }
    }
}

private struct RemainingBar: View {
    let share: Double
    let spent: Bool

    var body: some View {
        Rectangle()
            .fill(Palette.track)
            .frame(height: 2)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(spent ? Palette.spent : Palette.ink.opacity(0.82))
                    .scaleEffect(x: max(0, min(1, share)), y: 1, anchor: .leading)
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

private enum Palette {
    static let paper = Color(nsColor: .windowBackgroundColor)
    static let ink = Color.primary
    static let mute = Color.secondary
    static let track = Color.primary.opacity(0.12)
    static let spent = Color(red: 0.72, green: 0.22, blue: 0.16)
}
