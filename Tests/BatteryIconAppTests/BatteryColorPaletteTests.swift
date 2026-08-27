import Testing
@testable import BatteryIconApp

struct BatteryColorPaletteTests {
    @Test
    func criticalRangeStaysVisiblyRed() {
        for percentage in 0...BatteryColorPalette.criticalUpperBound {
            let color = BatteryColorPalette.components(for: percentage)

            #expect(color.red >= 0.95)
            #expect(color.green <= 0.13)
            #expect(color.blue <= 0.08)
        }
    }

    @Test
    func highLevelIsGreen() {
        let color = BatteryColorPalette.components(for: 100)

        #expect(color.green > color.red)
        #expect(color.green > color.blue)
    }

    @Test
    func valuesOutsideBatteryRangeAreClamped() {
        #expect(BatteryColorPalette.components(for: -20) == BatteryColorPalette.components(for: 0))
        #expect(BatteryColorPalette.components(for: 120) == BatteryColorPalette.components(for: 100))
    }
}
