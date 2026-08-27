import Foundation
import IOKit.ps

struct SystemBatteryReader: BatteryReading {
    func currentSnapshot() -> BatterySnapshot? {
        guard
            let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sourceList = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return nil
        }

        for source in sourceList {
            guard
                let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue()
                    as? [String: Any],
                description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
            else {
                continue
            }

            return makeSnapshot(from: description)
        }

        return nil
    }

    private func makeSnapshot(from description: [String: Any]) -> BatterySnapshot? {
        guard
            let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int,
            let maximumCapacity = description[kIOPSMaxCapacityKey] as? Int,
            maximumCapacity > 0
        else {
            return nil
        }

        let percentage = Int((Double(currentCapacity) / Double(maximumCapacity) * 100).rounded())
        let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
        let sourceState = description[kIOPSPowerSourceStateKey] as? String

        let powerState: BatterySnapshot.PowerState
        if isCharging {
            powerState = .charging
        } else if sourceState == kIOPSACPowerValue {
            powerState = .externalPower
        } else {
            powerState = .discharging
        }

        return BatterySnapshot(percentage: percentage, powerState: powerState)
    }
}
