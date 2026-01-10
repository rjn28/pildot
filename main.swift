
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
        // Attempt to fit in 22-24pt height.
        // Layout:
        // Top: Day (e.g. "sam") ~ 7pt height
        // Mid: Battery ~ 8pt height
        // Bot: Date (e.g. "10 ja") ~ 7pt height
        
        let totalHeight: CGFloat = 22
        
        // --- Prepare Data ---
        let date = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        
        // Day Name: "sam."
        formatter.dateFormat = "EE"
        let dayName = formatter.string(from: date).lowercased()
        
        // Day Number: "10"
        let dayNum = calendar.component(.day, from: date)
        
        // Month: "janvier" -> "ja"
        formatter.dateFormat = "MMMM"
        let monthFull = formatter.string(from: date).lowercased()
        let monthShort = String(monthFull.prefix(2))
        
        let dateBottomString = "\(dayNum) \(monthShort)"
        
        // Fonts
        let textFont = NSFont.systemFont(ofSize: 7, weight: .bold)
        let textAttrs: [NSAttributedString.Key: Any] = [.font: textFont, .foregroundColor: NSColor.labelColor]
        
        let topStr = NSAttributedString(string: dayName, attributes: textAttrs)
        let botStr = NSAttributedString(string: dateBottomString, attributes: textAttrs)
        
        let topSize = topStr.size()
        let botSize = botStr.size()
        
        // Battery Dimensions
        let batH: CGFloat = 8
        let batW: CGFloat = 22 // Narrower battery
        
        // Calculate max width
        let contentWidth = max(max(topSize.width, botSize.width), batW)
        let width = contentWidth + 2 // Tight padding
        
        let size = NSSize(width: width, height: totalHeight)
        
        // Create Image
        let img = NSImage(size: size, flipped: false) { rect in
            let _ = NSGraphicsContext.current!.cgContext
            
            let strokeColor = NSColor.labelColor
            strokeColor.setStroke()
            strokeColor.setFill() 
            
            // Layout Y (0 is bottom)
            // Bot Text: 0..6
            // Battery: 7..15
            // Top Text: 15..21
            
            // --- Draw Bottom Text (Date) ---
            let botY: CGFloat = 0.5
            let botX = (width - botSize.width) / 2
            botStr.draw(at: NSPoint(x: botX, y: botY))
            
            // --- Draw Top Text (Day) ---
            let topY: CGFloat = 15.5
            let topX = (width - topSize.width) / 2
            topStr.draw(at: NSPoint(x: topX, y: topY))
            
            // --- Draw Battery (Middle) ---
            let batY: CGFloat = 7.5
            let batX = (width - batW) / 2
            
            // Body
            let bodyRect = NSRect(x: batX, y: batY, width: batW - 2, height: batH)
            let path = NSBezierPath(roundedRect: bodyRect, xRadius: 1.5, yRadius: 1.5)
            path.lineWidth = 1.0
            path.stroke()
            
            // Nub
            let nubRect = NSRect(x: batX + batW - 2, y: batY + batH/2 - 1.5, width: 2, height: 3)
            let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 0.5, yRadius: 0.5)
            nubPath.fill()
            
            // Percentage (Inside Battery)
            let pctFont = NSFont.systemFont(ofSize: 6, weight: .bold) // Tiny font
            let pctAttrs: [NSAttributedString.Key: Any] = [.font: pctFont, .foregroundColor: NSColor.labelColor]
            let pctStr = NSAttributedString(string: "\(percentage)", attributes: pctAttrs)
            let pctSize = pctStr.size()
            
            let pctRect = NSRect(
                x: bodyRect.origin.x + (bodyRect.width - pctSize.width) / 2,
                y: bodyRect.origin.y + (bodyRect.height - pctSize.height) / 2 + 0.5,
                width: pctSize.width,
                height: pctSize.height
            )
            pctStr.draw(in: pctRect)
            
            return true
        }
        
        img.isTemplate = true
        return img
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
