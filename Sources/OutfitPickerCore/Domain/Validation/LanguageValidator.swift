import Foundation

struct LanguageValidator {
    private static let supportedLanguages: Set<String> = Set(
        SupportedLanguage.allCases.map { $0.rawValue }
    )

    static func validate(_ language: String?) throws {
        if let language, !supportedLanguages.contains(language) {
            throw ConfigError.unsupportedLanguage(language)
        }
    }

    static func isSupported(_ language: String) -> Bool {
        return supportedLanguages.contains(language)
    }

    static var allSupportedLanguages: Set<String> {
        return supportedLanguages
    }
}
