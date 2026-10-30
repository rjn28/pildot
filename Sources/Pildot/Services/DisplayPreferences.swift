import Foundation

@MainActor
final class DisplayPreferences {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var dateDisplayMode: DateDisplayMode {
        get {
            DateDisplayMode(rawValue: defaults.string(forKey: "dateDisplayMode") ?? "") ?? .hidden
        }
        set {
            defaults.set(newValue.rawValue, forKey: "dateDisplayMode")
        }
    }

    var dateLanguage: DateLanguage {
        get {
            DateLanguage(rawValue: defaults.string(forKey: "dateLanguage") ?? "") ?? .english
        }
        set {
            defaults.set(newValue.rawValue, forKey: "dateLanguage")
        }
    }
}
