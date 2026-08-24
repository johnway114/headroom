import Foundation
import HeadroomCore
import Observation
import ServiceManagement

@MainActor
@Observable
final class UsageStore {
    var snapshot: UsageSnapshot?
    var error: String?
    var isRefreshing = false
    var lastAttempt: Date?
    var clock = Date()

    var isBundled: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    var openAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private let cacheURL: URL
    private let ompOverride: URL?

    init(cacheURL: URL? = nil, ompOverride: URL? = nil) {
        self.ompOverride = ompOverride
        if let cacheURL {
            self.cacheURL = cacheURL
        } else {
            let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            let dir = base.appendingPathComponent("com.johnconway.headroom", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.cacheURL = dir.appendingPathComponent("last.json")
        }
        loadCache()
    }

    func start() async {
        let stale: Bool
        if let snapshot {
            stale = Date().timeIntervalSince(snapshot.generatedDate) > 120
        } else {
            stale = true
        }
        if stale {
            await refresh(force: false)
        }
    }

    func refresh(force: Bool) async {
        if isRefreshing { return }
        isRefreshing = true
        defer {
            isRefreshing = false
            lastAttempt = Date()
            clock = Date()
        }
        guard let omp = OmpPath.resolve(override: ompOverride) else {
            if snapshot == nil {
                error = UsageError.ompMissing.localizedDescription
            } else {
                error = UsageError.ompMissing.localizedDescription
            }
            return
        }
        do {
            let data = try await Task.detached {
                try UsageFetcher.fetchJSON(omp: omp, invalidate: force)
            }.value
            snapshot = try UsageSnapshot.decode(data)
            try? data.write(to: cacheURL, options: .atomic)
            error = nil
        } catch {
            if snapshot == nil {
                self.error = error.localizedDescription
            } else {
                self.error = error.localizedDescription
            }
        }
    }

    func tick() {
        clock = Date()
    }

    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let cached = try? UsageSnapshot.decode(data)
        else { return }
        snapshot = cached
    }
}
