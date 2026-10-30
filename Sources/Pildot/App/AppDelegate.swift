import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let monitor: BatteryMonitor
    private let renderer: StatusIconRenderer
    private let launchAtLoginManager: any LaunchAtLoginManaging
    private let displayPreferences: DisplayPreferences
    private var dateDisplayMenuItems: [NSMenuItem] = []
    private var dateLanguageMenuItems: [NSMenuItem] = []
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let batteryMenuItem = NSMenuItem(title: "Battery unavailable", action: nil, keyEquivalent: "")
    private let powerMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let launchAtLoginMenuItem = NSMenuItem(
        title: "Launch at Login",
        action: #selector(toggleLaunchAtLogin),
        keyEquivalent: ""
    )

    init(
        monitor: BatteryMonitor = BatteryMonitor(reader: SystemBatteryReader()),
        renderer: StatusIconRenderer = StatusIconRenderer(),
        launchAtLoginManager: any LaunchAtLoginManaging = LaunchAtLoginController(),
        displayPreferences: DisplayPreferences = DisplayPreferences()
    ) {
        self.monitor = monitor
        self.renderer = renderer
        self.launchAtLoginManager = launchAtLoginManager
        self.displayPreferences = displayPreferences
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
        updateDisplayMenuItems()
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

    @objc
    private func selectDateDisplay(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String,
              let mode = DateDisplayMode(rawValue: value) else { return }
        displayPreferences.dateDisplayMode = mode
        refreshDisplay()
    }

    @objc
    private func selectDateLanguage(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String,
              let language = DateLanguage(rawValue: value) else { return }
        displayPreferences.dateLanguage = language
        refreshDisplay()
    }

    private func refreshDisplay() {
        updateDisplayMenuItems()
        render(snapshot: monitor.currentSnapshot, isDimmed: monitor.isDimmed)
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
        let settingsMenu = NSMenu(title: "Settings")
        let dateDisplayMenu = NSMenu(title: "Date Display")
        for mode in DateDisplayMode.allCases {
            let item = NSMenuItem(
                title: mode == .hidden ? "None (Dot Only)" : "Day and Date",
                action: #selector(selectDateDisplay(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode.rawValue
            dateDisplayMenu.addItem(item)
            dateDisplayMenuItems.append(item)
        }
        let dateDisplayItem = NSMenuItem(title: "Date Display", action: nil, keyEquivalent: "")
        dateDisplayItem.submenu = dateDisplayMenu
        settingsMenu.addItem(dateDisplayItem)

        let dateLanguageMenu = NSMenu(title: "Date Language")
        for language in DateLanguage.allCases {
            let item = NSMenuItem(
                title: language == .french ? "Français" : "English",
                action: #selector(selectDateLanguage(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = language.rawValue
            dateLanguageMenu.addItem(item)
            dateLanguageMenuItems.append(item)
        }
        let dateLanguageItem = NSMenuItem(title: "Date Language", action: nil, keyEquivalent: "")
        dateLanguageItem.submenu = dateLanguageMenu
        settingsMenu.addItem(dateLanguageItem)
        settingsMenu.addItem(.separator())
        settingsMenu.addItem(launchAtLoginMenuItem)
        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        menu.setSubmenu(settingsMenu, for: settingsItem)
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Pildot",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageScaling = .scaleProportionallyDown
        updateLaunchAtLoginMenuItem()
        updateDisplayMenuItems()
    }

    private func render(snapshot: BatterySnapshot?, isDimmed: Bool) {
        statusItem.button?.image = renderer.image(
            for: snapshot,
            isDimmed: isDimmed,
            dateDisplayMode: displayPreferences.dateDisplayMode,
            dateLanguage: displayPreferences.dateLanguage
        )
        updateMenu(for: snapshot)
    }

    private func updateDisplayMenuItems() {
        for item in dateDisplayMenuItems {
            item.state = (item.representedObject as? String) == displayPreferences.dateDisplayMode.rawValue ? .on : .off
        }
        for item in dateLanguageMenuItems {
            item.state = (item.representedObject as? String) == displayPreferences.dateLanguage.rawValue ? .on : .off
        }
    }

    private func updateMenu(for snapshot: BatterySnapshot?) {
        guard let snapshot else {
            batteryMenuItem.title = "Battery unavailable"
            powerMenuItem.title = "No internal battery detected"
            statusItem.button?.toolTip = "Battery unavailable"
            statusItem.button?.setAccessibilityLabel("Battery unavailable")
            return
        }

        batteryMenuItem.title = "Battery: \(snapshot.percentage)%"
        powerMenuItem.title = snapshot.statusDescription
        let description = "Battery \(snapshot.percentage) percent, \(snapshot.statusDescription.lowercased())"
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
        alert.messageText = "Unable to change the launch at login setting"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
