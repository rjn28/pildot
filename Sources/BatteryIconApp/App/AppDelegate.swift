import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let monitor: BatteryMonitor
    private let renderer: StatusIconRenderer
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let batteryMenuItem = NSMenuItem(title: "Batterie indisponible", action: nil, keyEquivalent: "")
    private let powerMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")

    init(
        monitor: BatteryMonitor = BatteryMonitor(reader: SystemBatteryReader()),
        renderer: StatusIconRenderer = StatusIconRenderer()
    ) {
        self.monitor = monitor
        self.renderer = renderer
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        monitor.start { [weak self] snapshot, isDimmed in
            self?.render(snapshot: snapshot, isDimmed: isDimmed)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateMenu(for: monitor.currentSnapshot)
    }

    @objc
    private func quitApplication() {
        NSApp.terminate(nil)
    }

    private func configureStatusItem() {
        let menu = NSMenu()
        menu.delegate = self

        batteryMenuItem.isEnabled = false
        powerMenuItem.isEnabled = false
        menu.addItem(batteryMenuItem)
        menu.addItem(powerMenuItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quitter BatteryIconApp",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageScaling = .scaleProportionallyDown
    }

    private func render(snapshot: BatterySnapshot?, isDimmed: Bool) {
        statusItem.button?.image = renderer.image(for: snapshot, isDimmed: isDimmed)
        updateMenu(for: snapshot)
    }

    private func updateMenu(for snapshot: BatterySnapshot?) {
        guard let snapshot else {
            batteryMenuItem.title = "Batterie indisponible"
            powerMenuItem.title = "Aucune batterie interne détectée"
            statusItem.button?.toolTip = "Batterie indisponible"
            statusItem.button?.setAccessibilityLabel("Batterie indisponible")
            return
        }

        batteryMenuItem.title = "Batterie : \(snapshot.percentage) %"
        powerMenuItem.title = snapshot.statusDescription
        let description = "Batterie \(snapshot.percentage) pour cent, \(snapshot.statusDescription.lowercased())"
        statusItem.button?.toolTip = description
        statusItem.button?.setAccessibilityLabel(description)
    }
}
