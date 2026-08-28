import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let monitor: BatteryMonitor
    private let renderer: StatusIconRenderer
    private let launchAtLoginManager: any LaunchAtLoginManaging
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let batteryMenuItem = NSMenuItem(title: "Batterie indisponible", action: nil, keyEquivalent: "")
    private let powerMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let launchAtLoginMenuItem = NSMenuItem(
        title: "Lancer au démarrage",
        action: #selector(toggleLaunchAtLogin),
        keyEquivalent: ""
    )

    init(
        monitor: BatteryMonitor = BatteryMonitor(reader: SystemBatteryReader()),
        renderer: StatusIconRenderer = StatusIconRenderer(),
        launchAtLoginManager: any LaunchAtLoginManaging = LaunchAtLoginController()
    ) {
        self.monitor = monitor
        self.renderer = renderer
        self.launchAtLoginManager = launchAtLoginManager
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        monitor.start { [weak self] snapshot, isDimmed in
            self?.render(snapshot: snapshot, isDimmed: isDimmed)
        }
        applyLaunchArguments()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateMenu(for: monitor.currentSnapshot)
        updateLaunchAtLoginMenuItem()
    }

    @objc
    private func quitApplication() {
        NSApp.terminate(nil)
    }

    @objc
    private func toggleLaunchAtLogin() {
        do {
            try launchAtLoginManager.setEnabled(!launchAtLoginManager.isEnabled)
        } catch {
            presentLaunchAtLoginError(error)
        }
        updateLaunchAtLoginMenuItem()
    }

    private func configureStatusItem() {
        let menu = NSMenu()
        menu.delegate = self

        batteryMenuItem.isEnabled = false
        powerMenuItem.isEnabled = false
        menu.addItem(batteryMenuItem)
        menu.addItem(powerMenuItem)
        menu.addItem(.separator())

        launchAtLoginMenuItem.target = self
        let settingsMenu = NSMenu(title: "Réglages")
        settingsMenu.addItem(launchAtLoginMenuItem)
        let settingsItem = NSMenuItem(title: "Réglages", action: nil, keyEquivalent: "")
        menu.setSubmenu(settingsMenu, for: settingsItem)
        menu.addItem(settingsItem)
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
        updateLaunchAtLoginMenuItem()
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

    private func updateLaunchAtLoginMenuItem() {
        launchAtLoginMenuItem.state = launchAtLoginManager.isEnabled ? .on : .off
    }

    private func applyLaunchArguments() {
        let requestedState: Bool?
        if CommandLine.arguments.contains("--enable-launch-at-login") {
            requestedState = true
        } else if CommandLine.arguments.contains("--disable-launch-at-login") {
            requestedState = false
        } else {
            requestedState = nil
        }

        guard let requestedState else {
            return
        }

        do {
            try launchAtLoginManager.setEnabled(requestedState)
        } catch {
            presentLaunchAtLoginError(error)
        }
        updateLaunchAtLoginMenuItem()
    }

    private func presentLaunchAtLoginError(_ error: any Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Impossible de modifier le démarrage automatique"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
