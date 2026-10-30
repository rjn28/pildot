import AppKit
import Testing
@testable import Pildot

struct StatusIconRendererTests {
    @Test
    @MainActor
    func defaultIconIsOnlyACenteredDot() throws {
        let renderer = StatusIconRenderer()
        let snapshot = BatterySnapshot(percentage: 42, powerState: .discharging)
        let image = renderer.image(
            for: snapshot,
            isDimmed: false,
            date: Date(timeIntervalSince1970: 1_787_780_000)
        )

        #expect(image.size.height == 22)
        #expect(image.size.width == 12)
        #expect(!image.isTemplate)

        let imageData = try #require(image.tiffRepresentation)
        let bitmap = try #require(NSBitmapImageRep(data: imageData))
        let occupiedRows = (0..<bitmap.pixelsHigh).filter { y in
            (0..<bitmap.pixelsWide).contains { x in
                (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.1
            }
        }
        let firstRow = try #require(occupiedRows.first)
        let lastRow = try #require(occupiedRows.last)
        #expect(abs(Double(firstRow + lastRow) / 2 - Double(bitmap.pixelsHigh - 1) / 2) <= 1)
        #expect(lastRow - firstRow + 1 <= bitmap.pixelsHigh / 2)
    }

    @Test(arguments: [DateLanguage.english, .french])
    @MainActor
    func dateIncludesWeekdayAndNumberInSelectedLanguage(_ language: DateLanguage) throws {
        let renderer = StatusIconRenderer(timeZone: try #require(TimeZone(secondsFromGMT: 0)))
        let date = try #require(ISO8601DateFormatter().date(from: "2026-10-30T12:00:00Z"))
        let text = renderer.dateText(for: date, language: language)
        #expect(text == (language == .french ? "ven 30" : "fri 30"))

        let image = renderer.image(
            for: BatterySnapshot(percentage: 42, powerState: .discharging),
            isDimmed: false,
            date: date,
            dateDisplayMode: .dayAndDate,
            dateLanguage: language
        )
        #expect(image.size.height == 22)
        #expect(image.size.width > 12)
        #expect(image.size.width <= 40)
    }

    @Test
    @MainActor
    func dateUpdatesAcrossMonthBoundary() throws {
        let renderer = StatusIconRenderer(timeZone: try #require(TimeZone(secondsFromGMT: 0)))
        let formatter = ISO8601DateFormatter()
        let before = try #require(formatter.date(from: "2026-10-31T23:59:59Z"))
        let after = try #require(formatter.date(from: "2026-11-01T00:00:00Z"))
        #expect(renderer.dateText(for: before, language: .english) == "sat 31")
        #expect(renderer.dateText(for: after, language: .english) == "sun 1")
    }
}
