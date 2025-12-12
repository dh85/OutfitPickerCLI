import Foundation
import Testing

@testable import OutfitPickerCore

struct LanguageValidatorTests {
    @Test
    func validateNilLanguage() throws {
        try LanguageValidator.validate(nil)
    }

    @Test
    func validateSupportedLanguages() throws {
        let supportedCodes = ["en", "es", "fr", "de", "it", "pt", "ja", "zh", "ko", "ar", "hi"]
        for code in supportedCodes {
            try LanguageValidator.validate(code)
        }
    }

    @Test
    func validateUnsupportedLanguage() {
        #expect(throws: ConfigError.unsupportedLanguage("xyz")) {
            try LanguageValidator.validate("xyz")
        }
    }

    @Test
    func isSupportedReturnsTrueForValidLanguages() {
        #expect(LanguageValidator.isSupported("en"))
        #expect(LanguageValidator.isSupported("es"))
        #expect(LanguageValidator.isSupported("zh"))
    }

    @Test
    func isSupportedReturnsFalseForInvalidLanguages() {
        #expect(!LanguageValidator.isSupported("xyz"))
        #expect(!LanguageValidator.isSupported("invalid"))
        #expect(!LanguageValidator.isSupported(""))
    }

    @Test
    func allSupportedLanguagesContainsExpectedCount() {
        #expect(LanguageValidator.allSupportedLanguages.count == 51)
    }

    @Test
    func allSupportedLanguagesContainsMajorLanguages() {
        let major = ["en", "es", "fr", "de", "it", "pt", "ja", "zh", "ko", "ar", "hi", "ru"]
        for language in major {
            #expect(LanguageValidator.allSupportedLanguages.contains(language))
        }
    }
}
