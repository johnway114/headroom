import AppKit

@main
enum HeadroomMain {
    static func main() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        _ = FileManager.default.changeCurrentDirectoryPath(home)
        let openOnLaunch = CommandLine.arguments.contains("--open")
        let app = NSApplication.shared
        let delegate = AppDelegate(openOnLaunch: openOnLaunch)
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let openOnLaunch: Bool
    private var status: StatusItemController?
    private var store: UsageStore?

    init(openOnLaunch: Bool) {
        self.openOnLaunch = openOnLaunch
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if alreadyRunning() {
            NSApp.terminate(nil)
            return
        }
        let store = UsageStore()
        self.store = store
        let status = StatusItemController(store: store)
        self.status = status
        status.install()
        Task { await store.start() }
        if openOnLaunch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                status.showPopover()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        status?.showPopover()
        return false
    }

    private func alreadyRunning() -> Bool {
        let mine = Bundle.main.bundleIdentifier ?? "com.johnconway.headroom"
        let copies = NSRunningApplication.runningApplications(withBundleIdentifier: mine)
        return copies.count > 1
    }
}
