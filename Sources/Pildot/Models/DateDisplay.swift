import Foundation

enum DateDisplayMode: String, CaseIterable {
    case hidden
    case dayAndDate
}

enum DateLanguage: String, CaseIterable {
    case english
    case french

    var locale: Locale {
        Locale(identifier: self == .french ? "fr_FR" : "en_US")
    }
}
