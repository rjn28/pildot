
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
    var blinkState: Bool = true // true = visible, false = hidden
    var lastPercentage: Int = 100
    var lastIsCharging: Bool = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.action = #selector(menuClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            updateStatus()
        }
        
        // Update battery info every 10 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.updateStatus()
        }
    }
    
    @objc func menuClicked() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit BatteryIconApp", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    func updateStatus() {
        guard let info = getBatteryInfo() else { return }
        lastPercentage = info.percentage
        lastIsCharging = info.isCharging
        
        // Manage blink timer for low battery (<=15% and not charging)
        let shouldBlink = info.percentage <= 15 && !info.isCharging
        
        if shouldBlink {
            // Start blink timer if not already running
            if blinkTimer == nil {
                blinkState = true
                blinkTimer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.blinkState.toggle()
                    self.redrawIcon()
                }
                RunLoop.main.add(blinkTimer!, forMode: .common)
            }
        } else {
            // Stop blink timer
            blinkTimer?.invalidate()
            blinkTimer = nil
            blinkState = true
        }
        
        redrawIcon()
    }
    
    func redrawIcon() {
        let image = drawBatteryIcon(percentage: lastPercentage, isCharging: lastIsCharging, visible: blinkState)
        DispatchQueue.main.async {
            self.statusItem.button?.image = image
            self.statusItem.button?.imagePosition = .imageOnly
        }
    }
    
    func drawBatteryIcon(percentage: Int, isCharging: Bool, visible: Bool) -> NSImage {
        // Dimensions
        let totalHeight: CGFloat = 24
        let batH: CGFloat = 10
        let batW: CGFloat = 24
        
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
        let textFont = NSFont.monospacedSystemFont(ofSize: 8, weight: .semibold)
        let textAttrs: [NSAttributedString.Key: Any] = [.font: textFont, .foregroundColor: NSColor.labelColor]
        
        let topStr = NSAttributedString(string: dayName, attributes: textAttrs)
        let botStr = NSAttributedString(string: dateBottomString, attributes: textAttrs)
        
        let topSize = topStr.size()
        let botSize = botStr.size()
        
        let contentWidth = max(max(topSize.width, botSize.width), batW) + 4
        let width = contentWidth
        
        let size = NSSize(width: width, height: totalHeight)
        
        // Color based on percentage
        let batteryColor: NSColor
        if percentage > 60 {
            batteryColor = NSColor.systemGreen
        } else if percentage > 30 {
            batteryColor = NSColor.systemOrange
        } else {
            batteryColor = NSColor.systemRed
        }
        
        let img = NSImage(size: size, flipped: false) { rect in
            let _ = NSGraphicsContext.current!.cgContext
            
            // --- Top Text (Day) ---
            let topY: CGFloat = 17
            let topX = (width - topSize.width) / 2
            topStr.draw(at: NSPoint(x: topX, y: topY))
            
            // --- Bottom Text (Date) ---
            let botY: CGFloat = 0
            let botX = (width - botSize.width) / 2
            botStr.draw(at: NSPoint(x: botX, y: botY))
            
            // --- Battery (Middle) ---
            // Only draw if visible (for blink effect)
            if visible {
                let batY: CGFloat = 8
                let batX = (width - batW) / 2
                
                // Outer body (stroke only)
                let bodyRect = NSRect(x: batX + 0.5, y: batY + 0.5, width: batW - 3, height: batH - 1)
                let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 2, yRadius: 2)
                bodyPath.lineWidth = 1.2
                batteryColor.setStroke()
                bodyPath.stroke()
                
                // Nub (terminal)
                let nubRect = NSRect(x: batX + batW - 2.5, y: batY + batH/2 - 2, width: 2.5, height: 4)
                let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 1, yRadius: 1)
                batteryColor.setFill()
                nubPath.fill()
                
                // Fill level inside battery
                let fillPadding: CGFloat = 2
                let maxFillWidth = bodyRect.width - (fillPadding * 2)
                let fillWidth = maxFillWidth * CGFloat(percentage) / 100.0
                
                if fillWidth > 0 {
                    let fillRect = NSRect(
                        x: bodyRect.origin.x + fillPadding,
                        y: bodyRect.origin.y + fillPadding,
                        width: fillWidth,
                        height: bodyRect.height - (fillPadding * 2)
                    )
                    let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 1, yRadius: 1)
                    batteryColor.withAlphaComponent(0.35).setFill()
                    fillPath.fill()
                }
                
                // Percentage text (white with slight shadow for readability)
                let pctFont = NSFont.monospacedSystemFont(ofSize: 7, weight: .bold)
                let pctAttrs: [NSAttributedString.Key: Any] = [
                    .font: pctFont,
                    .foregroundColor: batteryColor
                ]
                let pctStr = NSAttributedString(string: "\(percentage)", attributes: pctAttrs)
                let pctSize = pctStr.size()
                
                let pctX = bodyRect.origin.x + (bodyRect.width - pctSize.width) / 2
                let pctY = bodyRect.origin.y + (bodyRect.height - pctSize.height) / 2 + 0.5
                pctStr.draw(at: NSPoint(x: pctX, y: pctY))
            }
            
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
