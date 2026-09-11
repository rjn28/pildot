struct BatterySnapshot: Equatable, Sendable {
    enum PowerState: Equatable, Sendable {
        case charging
        case externalPower
        case discharging
    }

    let percentage: Int
    let powerState: PowerState

    init(percentage: Int, powerState: PowerState) {
        self.percentage = min(max(percentage, 0), 100)
        self.powerState = powerState
    }

    var shouldBlink: Bool {
        percentage <= BatteryColorPalette.criticalUpperBound && powerState == .discharging
    }

    var statusDescription: String {
        switch powerState {
        case .charging:
            "En charge"
        case .externalPower:
            "Sur secteur"
        case .discharging:
            "Sur batterie"
        }
    }
}
