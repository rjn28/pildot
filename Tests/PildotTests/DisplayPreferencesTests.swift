import Foundation
import Testing
@testable import Pildot

@MainActor
struct DisplayPreferencesTests {
    @Test
    func freshInstallationShowsOnlyTheDot() throws {
        let suiteName = "PildotTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = DisplayPreferences(defaults: defaults)

        #expect(preferences.dateDisplayMode == .hidden)
        #expect(preferences.dateLanguage == .english)
    }

    @Test
    func choicesSurviveReloadAndHidingPreservesLanguage() throws {
        let suiteName = "PildotTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = DisplayPreferences(defaults: defaults)
        preferences.dateDisplayMode = .dayAndDate
        preferences.dateLanguage = .french

        let restored = DisplayPreferences(defaults: try #require(UserDefaults(suiteName: suiteName)))
        #expect(restored.dateDisplayMode == .dayAndDate)
        #expect(restored.dateLanguage == .french)

        restored.dateDisplayMode = .hidden
        #expect(preferences.dateDisplayMode == .hidden)
        #expect(preferences.dateLanguage == .french)
        restored.dateDisplayMode = .dayAndDate
        #expect(preferences.dateLanguage == .french)
    }

    @Test
    func unknownSavedValuesFallBackToDefaults() throws {
        let suiteName = "PildotTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("invalid", forKey: "dateDisplayMode")
        defaults.set("invalid", forKey: "dateLanguage")
        let preferences = DisplayPreferences(defaults: defaults)

        #expect(preferences.dateDisplayMode == .hidden)
        #expect(preferences.dateLanguage == .english)
    }
}
