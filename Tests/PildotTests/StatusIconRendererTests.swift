import Foundation
import Testing
@testable import Pildot

struct StatusIconRendererTests {
    @Test
    @MainActor
    func iconKeepsTheOriginalCompactFootprint() {
        let renderer = StatusIconRenderer(locale: Locale(identifier: "fr_FR"))
        let snapshot = BatterySnapshot(percentage: 42, powerState: .discharging)
        let image = renderer.image(
            for: snapshot,
            isDimmed: false,
            date: Date(timeIntervalSince1970: 1_787_780_000)
        )

        #expect(image.size.height == 22)
        #expect(image.size.width >= 20)
        #expect(image.size.width <= 40)
        #expect(!image.isTemplate)
    }
}
