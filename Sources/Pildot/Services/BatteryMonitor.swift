import Foundation

@MainActor
final class BatteryMonitor: NSObject {
    typealias ChangeHandler = @MainActor (_ snapshot: BatterySnapshot?, _ isDimmed: Bool) -> Void

    private let reader: any BatteryReading
    private let refreshInterval: TimeInterval
    private let blinkInterval: TimeInterval
    private var refreshTimer: Timer?
    private var blinkTimer: Timer?
    private var changeHandler: ChangeHandler?
    private var renderedDay: Date?
    private(set) var isDimmed = false

    private(set) var currentSnapshot: BatterySnapshot?

    init(
        reader: any BatteryReading,
        refreshInterval: TimeInterval = 30,
        blinkInterval: TimeInterval = 0.65
    ) {
        self.reader = reader
        self.refreshInterval = refreshInterval
        self.blinkInterval = blinkInterval
    }

    func start(onChange: @escaping ChangeHandler) {
        stop()
        changeHandler = onChange
        refresh()

        let timer = Timer(
            timeInterval: refreshInterval,
            target: self,
            selector: #selector(refreshTimerDidFire(_:)),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    func stop() {
        refreshTimer?.invalidate()
        blinkTimer?.invalidate()
        refreshTimer = nil
        blinkTimer = nil
        changeHandler = nil
        isDimmed = false
    }

    @objc
    private func refreshTimerDidFire(_ timer: Timer) {
        refresh()
    }

    @objc
    private func blinkTimerDidFire(_ timer: Timer) {
        guard currentSnapshot?.shouldBlink == true else {
            stopBlinking(emitIfDimmed: true)
            return
        }

        isDimmed.toggle()
        emitChange()
    }

    private func refresh() {
        let newSnapshot = reader.currentSnapshot()
        let currentDay = Calendar.autoupdatingCurrent.startOfDay(for: Date())
        let batteryChanged = newSnapshot != currentSnapshot
        let dayChanged = currentDay != renderedDay

        currentSnapshot = newSnapshot
        renderedDay = currentDay
        updateBlinking(for: newSnapshot)

        if batteryChanged || dayChanged {
            emitChange()
        }
    }

    private func updateBlinking(for snapshot: BatterySnapshot?) {
        guard snapshot?.shouldBlink == true else {
            stopBlinking(emitIfDimmed: false)
            return
        }

        guard blinkTimer == nil else {
            return
        }

        isDimmed = false
        let timer = Timer(
            timeInterval: blinkInterval,
            target: self,
            selector: #selector(blinkTimerDidFire(_:)),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        blinkTimer = timer
    }

    private func stopBlinking(emitIfDimmed: Bool) {
        let needsRefresh = isDimmed
        blinkTimer?.invalidate()
        blinkTimer = nil
        isDimmed = false

        if needsRefresh && emitIfDimmed {
            emitChange()
        }
    }

    private func emitChange() {
        changeHandler?(currentSnapshot, isDimmed)
    }
}
