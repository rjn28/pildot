
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
        let width: CGFloat = 26 // Slightly wider to fit text
        let height: CGFloat = 13 // Standard menu bar icon height roughly
        let size = NSSize(width: width, height: height)
        
        let img = NSImage(size: size, flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext
            
            let strokeColor = NSColor.labelColor
            strokeColor.setStroke()
            strokeColor.setFill() // For text
            
            // Battery Body
            let bodyRect = NSRect(x: 1, y: 1, width: width - 3, height: height - 2)
            let path = NSBezierPath(roundedRect: bodyRect, xRadius: 2, yRadius: 2)
            path.lineWidth = 1.0
            path.stroke()
            
            // Battery Nub
            let nubRect = NSRect(x: width - 2, y: height/2 - 2, width: 2, height: 4)
            let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 1, yRadius: 1)
            nubPath.fill() // Fill the nub
            
            // Fill Level (Optional, maybe just text is better for readability as per request)
            // If we fill it, text might be hard to read unless we invert color.
            // Let's draw text inside.
            
            let text = "\(percentage)"
            let font = NSFont.systemFont(ofSize: 9, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.labelColor
            ]
            
            let ts = NSAttributedString(string: text, attributes: attrs)
            let textSize = ts.size()
            
            // Center text
            let textRect = NSRect(
                x: bodyRect.origin.x + (bodyRect.width - textSize.width) / 2,
                y: bodyRect.origin.y + (bodyRect.height - textSize.height) / 2 + 1, // +1 for visual centering
                width: textSize.width,
                height: textSize.height
            )
            
            ts.draw(in: textRect)
            
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
