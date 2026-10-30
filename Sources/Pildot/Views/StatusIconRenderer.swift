import AppKit

@MainActor
final class StatusIconRenderer {
    private enum Metrics {
        static let totalHeight: CGFloat = 22
        static let horizontalPadding: CGFloat = 2
        static let dateBaseline: CGFloat = 13
        static let dotSize: CGFloat = 8
        static let dotBaseline: CGFloat = 2
    }

    private let dateFormatters: [DateLanguage: DateFormatter]

    init(timeZone: TimeZone = .autoupdatingCurrent) {
        dateFormatters = Dictionary(uniqueKeysWithValues: DateLanguage.allCases.map { language in
            let formatter = DateFormatter()
            formatter.locale = language.locale
            formatter.timeZone = timeZone
            formatter.dateFormat = "EEE d"
            return (language, formatter)
        })
    }

    func dateText(for date: Date, language: DateLanguage) -> String {
        dateFormatters[language]!.string(from: date)
            .replacingOccurrences(of: ".", with: "")
            .lowercased()
    }

    func image(
        for snapshot: BatterySnapshot?,
        isDimmed: Bool,
        date: Date = Date(),
        dateDisplayMode: DateDisplayMode = .hidden,
        dateLanguage: DateLanguage = .english
    ) -> NSImage {
        let dateString: NSAttributedString? = dateDisplayMode == .hidden ? nil : NSAttributedString(
            string: dateText(for: date, language: dateLanguage),
            attributes: [
                .font: NSFont.systemFont(ofSize: 8, weight: .medium),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        let dateSize = dateString?.size() ?? .zero
        let width = ceil(max(dateSize.width, Metrics.dotSize)) + (Metrics.horizontalPadding * 2)
        let size = NSSize(width: width, height: Metrics.totalHeight)
        let dotColor = color(for: snapshot, isDimmed: isDimmed)
        let dotBaseline = dateString == nil
            ? (Metrics.totalHeight - Metrics.dotSize) / 2
            : Metrics.dotBaseline

        let image = NSImage(size: size, flipped: false) { _ in
            let dateOrigin = NSPoint(
                x: (width - dateSize.width) / 2,
                y: Metrics.dateBaseline
            )
            dateString?.draw(at: dateOrigin)

            let dotRect = NSRect(
                x: (width - Metrics.dotSize) / 2,
                y: dotBaseline,
                width: Metrics.dotSize,
                height: Metrics.dotSize
            )
            dotColor.setFill()
            NSBezierPath(ovalIn: dotRect).fill()
            return true
        }

        image.isTemplate = false
        return image
    }

    private func color(for snapshot: BatterySnapshot?, isDimmed: Bool) -> NSColor {
        guard let snapshot else {
            return NSColor.secondaryLabelColor.withAlphaComponent(0.45)
        }

        let components = BatteryColorPalette.components(for: snapshot.percentage)
        let alpha: CGFloat = isDimmed ? 0.16 : 1
        return NSColor(
            srgbRed: components.red,
            green: components.green,
            blue: components.blue,
            alpha: alpha
        )
    }
}
