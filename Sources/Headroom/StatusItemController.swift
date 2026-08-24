import AppKit
import HeadroomCore
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let store: UsageStore
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let fallbackWindow: NSWindow
    private var refreshTimer: Timer?
    private var clockTimer: Timer?
    private var snapshotWatch: Task<Void, Never>?

    init(store: UsageStore) {
        self.store = store
        let positionKey = "NSStatusItem Preferred Position headroom"
        let current = UserDefaults.standard.object(forKey: positionKey) as? Double
        if current == nil || (current ?? 0) < 500 {
            UserDefaults.standard.set(560.0, forKey: positionKey)
        }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.autosaveName = NSStatusItem.AutosaveName("headroom")
        self.statusItem = item
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 2, height: 2),
            styleMask: .borderless,
            backing: .buffered,
            defer: true
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.fallbackWindow = window
        super.init()
    }

    func install() {
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self
        popover.contentSize = NSSize(width: 312, height: 80)
        let root = UsagePopoverView(store: store)
        let hosting = PopoverHostingController(rootView: root)
        hosting.onSizeChange = { [weak self] size in
            guard size.width > 0, size.height > 40 else { return }
            self?.popover.contentSize = NSSize(width: 312, height: size.height)
        }
        popover.contentViewController = hosting

        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.setAccessibilityLabel("Headroom")
        button.setAccessibilityIdentifier("Headroom")
        button.target = self
        button.action = #selector(togglePopover)
        button.sendAction(on: [.leftMouseUp])
        renderButton()

        snapshotWatch = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                self.renderButton()
                try? await Task.sleep(for: .milliseconds(400))
            }
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.store.refresh(force: false)
                self.renderButton()
            }
        }
        clockTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.store.tick()
                if self.popover.isShown {
                    self.renderButton()
                }
            }
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown { return }
        NSApp.activate(ignoringOtherApps: true)
        if buttonIsOnScreen(button) {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            button.highlight(true)
        } else if let view = fallbackWindow.contentView, let screen = NSScreen.main {
            let origin = NSPoint(x: screen.frame.maxX - 328, y: screen.visibleFrame.maxY - 2)
            fallbackWindow.setFrame(NSRect(origin: origin, size: NSSize(width: 2, height: 2)), display: false)
            fallbackWindow.orderFront(nil)
            popover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        }
        Task { await store.refresh(force: false) }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    func popoverDidClose(_ notification: Notification) {
        statusItem.button?.highlight(false)
        fallbackWindow.orderOut(nil)
    }

    private func buttonIsOnScreen(_ button: NSStatusBarButton) -> Bool {
        guard let window = button.window else { return false }
        let frame = window.convertToScreen(button.bounds)
        guard let screen = NSScreen.main else { return frame.width > 2 }
        return frame.width > 2
            && frame.minX > screen.visibleFrame.minX + 8
            && frame.maxX < screen.visibleFrame.maxX + 8
            && frame.minY > screen.visibleFrame.minY
    }

    private func renderButton() {
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
        button.title = ""
        button.attributedTitle = NSAttributedString()
        if let snapshot = store.snapshot, let tightest = snapshot.tightest {
            let remaining = tightest.1.remainingShare
            button.image = MenuBarIcon.make(remaining: remaining)
            button.toolTip = Format.tooltip(for: snapshot, now: store.clock)
            button.setAccessibilityValue("\(Format.remainingPercent(tightest.1.amount)) percent remaining")
        } else if store.error != nil {
            button.image = MenuBarIcon.make(remaining: nil)
            button.toolTip = store.error
            button.setAccessibilityValue("error")
        } else {
            button.image = MenuBarIcon.make(remaining: nil)
            button.toolTip = "Headroom"
            button.setAccessibilityValue("loading")
        }
    }
}

private final class PopoverHostingController<Content: View>: NSHostingController<Content> {
    var onSizeChange: ((NSSize) -> Void)?

    override func viewDidLayout() {
        super.viewDidLayout()
        view.layoutSubtreeIfNeeded()
        var size = view.fittingSize
        size.width = 312
        guard size.height > 60, size.height < 900 else { return }
        if preferredContentSize != size {
            preferredContentSize = size
            onSizeChange?(size)
        }
    }
}
