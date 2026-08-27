import Testing
@testable import BatteryIconApp

struct BatterySnapshotTests {
    @Test
    func percentageIsClamped() {
        #expect(BatterySnapshot(percentage: -1, powerState: .discharging).percentage == 0)
        #expect(BatterySnapshot(percentage: 101, powerState: .charging).percentage == 100)
    }

    @Test
    func onlyCriticalDischargingBatteryBlinks() {
        #expect(BatterySnapshot(percentage: 15, powerState: .discharging).shouldBlink)
        #expect(!BatterySnapshot(percentage: 16, powerState: .discharging).shouldBlink)
        #expect(!BatterySnapshot(percentage: 10, powerState: .charging).shouldBlink)
        #expect(!BatterySnapshot(percentage: 10, powerState: .externalPower).shouldBlink)
    }
}
