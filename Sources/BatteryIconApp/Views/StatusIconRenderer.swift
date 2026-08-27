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

    private let dateFormatter: DateFormatter

    init(locale: Locale = Locale(identifier: "fr_FR")) {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEE d")
        dateFormatter = formatter
    }

    func image(for snapshot: BatterySnapshot?, isDimmed: Bool, date: Date = Date()) -> NSImage {
        let dateLine = dateFormatter.string(from: date)
            .replacingOccurrences(of: ".", with: "")
            .lowercased()
        let dateString = NSAttributedString(
            string: dateLine,
            attributes: [
                .font: NSFont.systemFont(ofSize: 8, weight: .medium),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        let dateSize = dateString.size()
        let width = ceil(max(dateSize.width, Metrics.dotSize)) + (Metrics.horizontalPadding * 2)
        let size = NSSize(width: width, height: Metrics.totalHeight)
        let dotColor = color(for: snapshot, isDimmed: isDimmed)

        let image = NSImage(size: size, flipped: false) { _ in
            let dateOrigin = NSPoint(
                x: (width - dateSize.width) / 2,
                y: Metrics.dateBaseline
            )
            dateString.draw(at: dateOrigin)

            let dotRect = NSRect(
                x: (width - Metrics.dotSize) / 2,
                y: Metrics.dotBaseline,
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
