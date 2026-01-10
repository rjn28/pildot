
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
    
    // Example: ... 56%; discharging; ... or ... 100%; charged; ...
    // Regex to capture digits before %
    // We look for line containing "InternalBattery" or just the % pattern
    
    let range = NSRange(location: 0, length: output.utf16.count)
    let regex = try! NSRegularExpression(pattern: "(\\d+)%")
    
    if let match = regex.firstMatch(in: output, options: [], range: range) {
        if let swiftRange = Range(match.range(at: 1), in: output) {
            let percentPart = output[swiftRange]
            let percentCheck = Int(percentPart) ?? 0
            
            // Basic check for charging based on words like 'charging', 'AC attached' usually in pmset output
            // 'AC Power' in first line means plugged in usually, but let's check text
            let isCharging = output.contains("charging") || output.contains("AC attached") || output.contains("charged")
            
            return BatteryInfo(percentage: percentCheck, isCharging: isCharging)
        }
    }
    
    return nil
}

// MARK: - Status Bar Controller
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.action = #selector(menuClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            updateStatus()
        }
        
        // Update every 5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateStatus()
        }
    }
    
    @objc func menuClicked() {
        // Simple quit on click for now, or maybe a menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil) // Trigger menu opening
        statusItem.menu = nil // Clear it so simple verification doesn't get stuck? 
        // Actually standard behavior is to attach menu to statusItem.menu, but let's just do that.
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    func updateStatus() {
        guard let info = getBatteryInfo() else { return }
        let image = drawBatteryIcon(percentage: info.percentage, isCharging: info.isCharging)
        DispatchQueue.main.async {
            self.statusItem.button?.image = image
            // We don't set title to save space as requested
            self.statusItem.button?.imagePosition = .imageOnly
        }
    }
    
    func drawBatteryIcon(percentage: Int, isCharging: Bool) -> NSImage {
        // Total available height is roughly 22pt, width can be variable
        let totalHeight: CGFloat = 22
        
        // Date String: e.g. "sam. 10"
        let date = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "E d" // Short day + day number (e.g., "sam. 10")
        let dateString = formatter.string(from: date).lowercased()
        
        let font = NSFont.systemFont(ofSize: 9, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
        let dateStr = NSAttributedString(string: dateString, attributes: attrs)
        let dateSize = dateStr.size()
        
        // Calculate needed width: max of date text or battery width
        let batteryWidth: CGFloat = 26
        let width = max(dateSize.width, batteryWidth) + 4 // Add some padding
        
        // Height 22 to fit in status bar usually
        let size = NSSize(width: width, height: totalHeight)
        
        let img = NSImage(size: size, flipped: false) { rect in
            let _ = NSGraphicsContext.current!.cgContext
            
            let strokeColor = NSColor.labelColor
            strokeColor.setStroke()
            strokeColor.setFill() // For text
            
            // --- Draw Date (Top) ---
            // Y coordinates: (0,0) is bottom-left in default Cocoa (non-flipped).
            // We want Date at Top (~11-22), Battery at Bottom (~0-11).
            
            // Draw text at top
            let textY: CGFloat = 11
            dateStr.draw(at: NSPoint(x: (width - dateSize.width) / 2, y: textY))
            
            // --- Draw Battery (Bottom) ---
            let batHeight: CGFloat = 10
            let batY: CGFloat = 1 // 1pt padding from bottom
            let batWidth: CGFloat = 24
            // Center battery horizontally
            let batX: CGFloat = (width - batWidth) / 2
            
            // Battery Body
            let bodyRect = NSRect(x: batX, y: batY, width: batWidth - 2, height: batHeight)
            let path = NSBezierPath(roundedRect: bodyRect, xRadius: 2, yRadius: 2)
            path.lineWidth = 1.0
            path.stroke()
            
            // Battery Nub
            let nubRect = NSRect(x: batX + batWidth - 2, y: batY + batHeight/2 - 2, width: 2, height: 4)
            let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 1, yRadius: 1)
            nubPath.fill() // Fill the nub
            
            // Fill Level / Text inside Battery
            let pctFont = NSFont.systemFont(ofSize: 8, weight: .bold)
            let pctAttrs: [NSAttributedString.Key: Any] = [
                .font: pctFont,
                .foregroundColor: NSColor.labelColor
            ]
            
            let pctText = "\(percentage)"
            let pctStr = NSAttributedString(string: pctText, attributes: pctAttrs)
            let pctSize = pctStr.size()
            
            // Center text inside battery body
            let pctRect = NSRect(
                x: bodyRect.origin.x + (bodyRect.width - pctSize.width) / 2,
                y: bodyRect.origin.y + (bodyRect.height - pctSize.height) / 2 + 0.5,
                width: pctSize.width,
                height: pctSize.height
            )
            
            pctStr.draw(in: pctRect)
            
            return true
        }
        
        img.isTemplate = true // Allows it to adapt to dark/light mode automatically
        return img
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
