
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
        // Creative "Minimal Stack" Design
        // Line 1: Day + Day Number (e.g., "dim 11")
        // Line 2: Large percentage with charging indicator
        
        let totalHeight: CGFloat = 22
        
        // Date info
        let date = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        
        // Day name shortened (dim, lun, mar...)
        formatter.dateFormat = "E"
        let dayName = formatter.string(from: date).replacingOccurrences(of: ".", with: "").lowercased()
        
        // Day number
        let dayNum = calendar.component(.day, from: date)
        
        // Combined date line
        let dateLine = "\(dayName) \(dayNum)"
        
        // Smooth gradient color from green (100%) to red (0%)
        // Using HSB: Green = 120°, Red = 0°
        // Interpolate hue based on percentage
        let hue = CGFloat(percentage) / 100.0 * 0.33  // 0.33 = green, 0.0 = red in HSB
        let batteryColor = NSColor(hue: hue, saturation: 0.85, brightness: 0.95, alpha: 1.0)
        
        // Flash effect for low battery
        let displayColor: NSColor
        if flash {
            displayColor = batteryColor.withAlphaComponent(0.15)
        } else {
            displayColor = batteryColor
        }
        
        // Fonts - Use rounded design for modern feel
        let dateFont = NSFont.systemFont(ofSize: 8, weight: .medium)
        let pctFont = NSFont.systemFont(ofSize: 11, weight: .bold)
        
        // Date line attributes (subtle, secondary)
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let dateStr = NSAttributedString(string: dateLine, attributes: dateAttrs)
        let dateSize = dateStr.size()
        
        // Percentage text (simple, no charging indicator)
        let pctText = "\(percentage)%"
        
        let pctAttrs: [NSAttributedString.Key: Any] = [
            .font: pctFont,
            .foregroundColor: displayColor
        ]
        let pctStr = NSAttributedString(string: pctText, attributes: pctAttrs)
        let pctSize = pctStr.size()
        
        // Calculate width
        let contentWidth = max(dateSize.width, pctSize.width)
        let width = contentWidth + 4
        
        let size = NSSize(width: width, height: totalHeight)
        
        let img = NSImage(size: size, flipped: false) { rect in
            let _ = NSGraphicsContext.current!.cgContext
            
            // --- Top: Date line (subtle) ---
            let dateY: CGFloat = 13
            let dateX = (width - dateSize.width) / 2
            dateStr.draw(at: NSPoint(x: dateX, y: dateY))
            
            // --- Bottom: Percentage (prominent) ---
            let pctY: CGFloat = 1
            let pctX = (width - pctSize.width) / 2
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
