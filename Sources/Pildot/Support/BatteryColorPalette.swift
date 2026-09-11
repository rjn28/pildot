struct RGBComponents: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
}

enum BatteryColorPalette {
    static let criticalUpperBound = 15

    private struct Anchor: Sendable {
        let percentage: Double
        let color: RGBComponents
    }

    // The critical range deliberately stays red. The previous hue formula had
    // already drifted into orange at 15%, making the alert hard to read.
    private static let anchors = [
        Anchor(percentage: 0, color: RGBComponents(red: 0.96, green: 0.05, blue: 0.07)),
        Anchor(percentage: 15, color: RGBComponents(red: 1.00, green: 0.13, blue: 0.08)),
        Anchor(percentage: 30, color: RGBComponents(red: 1.00, green: 0.48, blue: 0.04)),
        Anchor(percentage: 55, color: RGBComponents(red: 0.96, green: 0.75, blue: 0.05)),
        Anchor(percentage: 80, color: RGBComponents(red: 0.26, green: 0.78, blue: 0.25)),
        Anchor(percentage: 100, color: RGBComponents(red: 0.10, green: 0.72, blue: 0.27))
    ]

    static func components(for percentage: Int) -> RGBComponents {
        let level = Double(min(max(percentage, 0), 100))

        guard let upperIndex = anchors.firstIndex(where: { $0.percentage >= level }) else {
            return anchors[anchors.count - 1].color
        }

        guard upperIndex > 0 else {
            return anchors[0].color
        }

        let lower = anchors[upperIndex - 1]
        let upper = anchors[upperIndex]
        let linearProgress = (level - lower.percentage) / (upper.percentage - lower.percentage)
        let easedProgress = linearProgress * linearProgress * (3 - (2 * linearProgress))

        return RGBComponents(
            red: interpolate(lower.color.red, upper.color.red, progress: easedProgress),
            green: interpolate(lower.color.green, upper.color.green, progress: easedProgress),
            blue: interpolate(lower.color.blue, upper.color.blue, progress: easedProgress)
        )
    }

    private static func interpolate(_ start: Double, _ end: Double, progress: Double) -> Double {
        start + ((end - start) * progress)
    }
}
