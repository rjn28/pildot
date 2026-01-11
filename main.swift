
import AppKit
import Foundation

// MARK: - Battery Helper
struct BatteryInfo {
    var percentage: Int
    var isCharging: Bool
}

func getBatteryInfo() -> BatteryInfo? {
    let process = Process()
    process.launchPath = "/usr/bin/pmset"
    process.arguments = ["-g", "batt"]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.launch()
    process.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let output = String(data: data, encoding: .utf8) else { return nil }
    
    let range = NSRange(location: 0, length: output.utf16.count)
    let regex = try! NSRegularExpression(pattern: "(\\d+)%")
    
    if let match = regex.firstMatch(in: output, options: [], range: range) {
        if let swiftRange = Range(match.range(at: 1), in: output) {
            let percentPart = output[swiftRange]
            let percentCheck = Int(percentPart) ?? 0
            let isCharging = output.contains("charging") || output.contains("AC attached") || output.contains("charged")
            return BatteryInfo(percentage: percentCheck, isCharging: isCharging)
        }
    }
    
    return nil
}

// MARK: - Status Bar Controller
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var updateTimer: Timer?
    var blinkTimer: Timer?
    var blinkPhase: Int = 0  // 0 = normal, 1 = flash
    var lastPercentage: Int = 100
    var lastIsCharging: Bool = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.action = #selector(menuClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Initial update
        updateBatteryInfo()
        redrawIcon()
        
        // Update battery info every 10 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateBatteryInfo()
            self?.redrawIcon()
        }
        RunLoop.main.add(updateTimer!, forMode: .common)
        
        // Blink timer runs constantly but only affects display when needed
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.blinkPhase = (self.blinkPhase + 1) % 2
            // Only redraw if we should be blinking
            if self.lastPercentage <= 15 && !self.lastIsCharging {
                self.redrawIcon()
            }
        }
        RunLoop.main.add(blinkTimer!, forMode: .common)
    }
    
    @objc func menuClicked() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Batterie: \(lastPercentage)%", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quitter", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    func updateBatteryInfo() {
        guard let info = getBatteryInfo() else { return }
        lastPercentage = info.percentage
        lastIsCharging = info.isCharging
    }
    
    func redrawIcon() {
        // Determine if we should show "flash" state
        let shouldBlink = lastPercentage <= 15 && !lastIsCharging
        let isFlashPhase = shouldBlink && (blinkPhase == 1)
        
        let image = drawBatteryIcon(percentage: lastPercentage, isCharging: lastIsCharging, flash: isFlashPhase)
        
        DispatchQueue.main.async {
            self.statusItem.button?.image = image
            self.statusItem.button?.imagePosition = .imageOnly
        }
    }
    
    func drawBatteryIcon(percentage: Int, isCharging: Bool, flash: Bool) -> NSImage {
        // Layout: Horizontal arrangement
        // Left side: Vertical battery (tall, thin)
        // Right side: Percentage text
        // Top: Day name
        // Bottom: Date
        
        let totalHeight: CGFloat = 22
        
        // Date info
        let date = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        
        formatter.dateFormat = "EE"
        let dayName = formatter.string(from: date).replacingOccurrences(of: ".", with: "").lowercased()
        
        let dayNum = calendar.component(.day, from: date)
        
        formatter.dateFormat = "MMM"
        let monthShort = formatter.string(from: date).replacingOccurrences(of: ".", with: "").prefix(2).lowercased()
        
        let dateBottomString = "\(dayNum) \(monthShort)"
        
        // Fonts
        let textFont = NSFont.monospacedSystemFont(ofSize: 7, weight: .semibold)
        let textAttrs: [NSAttributedString.Key: Any] = [.font: textFont, .foregroundColor: NSColor.labelColor]
        
        let topStr = NSAttributedString(string: dayName, attributes: textAttrs)
        let botStr = NSAttributedString(string: dateBottomString, attributes: textAttrs)
        
        let topSize = topStr.size()
        let botSize = botStr.size()
        
        // Vertical battery dimensions (thin and tall)
        let batW: CGFloat = 8  // Width of vertical battery
        let batH: CGFloat = 12 // Height of vertical battery (fits between text rows)
        
        // Percentage text
        let pctFont = NSFont.monospacedSystemFont(ofSize: 8, weight: .bold)
        
        // Color based on percentage
        var batteryColor: NSColor
        if percentage > 60 {
            batteryColor = NSColor.systemGreen
        } else if percentage > 30 {
            batteryColor = NSColor.systemOrange
        } else {
            batteryColor = NSColor.systemRed
        }
        
        // Flash effect
        let displayColor: NSColor
        if flash {
            displayColor = batteryColor.withAlphaComponent(0.2)
        } else {
            displayColor = batteryColor
        }
        
        let pctAttrs: [NSAttributedString.Key: Any] = [.font: pctFont, .foregroundColor: displayColor]
        let pctStr = NSAttributedString(string: "\(percentage)", attributes: pctAttrs)
        let pctSize = pctStr.size()
        
        // Calculate total width: battery + gap + percentage
        let batteryPlusPct = batW + 2 + pctSize.width
        let contentWidth = max(max(topSize.width, botSize.width), batteryPlusPct)
        let width = contentWidth + 2
        
        let size = NSSize(width: width, height: totalHeight)
        
        let img = NSImage(size: size, flipped: false) { rect in
            let _ = NSGraphicsContext.current!.cgContext
            
            // --- Top Text (Day) ---
            let topY: CGFloat = 15
            let topX = (width - topSize.width) / 2
            topStr.draw(at: NSPoint(x: topX, y: topY))
            
            // --- Bottom Text (Date) ---
            let botY: CGFloat = 0
            let botX = (width - botSize.width) / 2
            botStr.draw(at: NSPoint(x: botX, y: botY))
            
            // --- Vertical Battery + Percentage (Middle row) ---
            // Center the battery+pct group horizontally
            let groupWidth = batW + 2 + pctSize.width
            let groupX = (width - groupWidth) / 2
            
            let batX = groupX
            let batY: CGFloat = 7  // Middle zone
            
            // Nub on top (small rectangle)
            let nubW: CGFloat = 4
            let nubH: CGFloat = 2
            let nubRect = NSRect(x: batX + (batW - nubW) / 2, y: batY + batH - 0.5, width: nubW, height: nubH)
            let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 0.5, yRadius: 0.5)
            displayColor.setFill()
            nubPath.fill()
            
            // Battery body (stroke)
            let bodyRect = NSRect(x: batX + 0.5, y: batY + 0.5, width: batW - 1, height: batH - 2)
            let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 1.5, yRadius: 1.5)
            bodyPath.lineWidth = 1.2
            displayColor.setStroke()
            bodyPath.stroke()
            
            // Fill level (from bottom up)
            let fillPadding: CGFloat = 1.5
            let maxFillHeight = bodyRect.height - (fillPadding * 2)
            let fillHeight = maxFillHeight * CGFloat(percentage) / 100.0
            
            if fillHeight > 0 {
                let fillRect = NSRect(
                    x: bodyRect.origin.x + fillPadding,
                    y: bodyRect.origin.y + fillPadding,
                    width: bodyRect.width - (fillPadding * 2),
                    height: fillHeight
                )
                let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 0.5, yRadius: 0.5)
                displayColor.withAlphaComponent(0.5).setFill()
                fillPath.fill()
            }
            
            // Percentage text to the right of battery
            let pctX = batX + batW + 2
            let pctY = batY + (batH - pctSize.height) / 2
            pctStr.draw(at: NSPoint(x: pctX, y: pctY))
            
            return true
        }
        
        img.isTemplate = false
        return img
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
