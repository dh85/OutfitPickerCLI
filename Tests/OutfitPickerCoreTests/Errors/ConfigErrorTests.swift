import Foundation
import Testing

@testable import OutfitPickerCore

struct ConfigErrorTests {
    @Test
    func errorDescriptions() {
        testErrorDescriptions([
            (ConfigError.emptyRoot, "empty root in configuration"),
            (ConfigError.missingRoot, "missing root in configuration"),
            (ConfigError.missingLanguage, "missing language in configuration"),
            (ConfigError.unsupportedLanguage("fr"), "unsupported language: fr"),
            (ConfigError.pathTraversalNotAllowed, "path traversal not allowed"),
            (ConfigError.pathTooLong, "path too long"),
            (ConfigError.restrictedPath, "restricted path"),
            (ConfigError.symlinkNotAllowed, "symlink not allowed"),
            (ConfigError.invalidCharacters, "invalid characters"),
        ])
    }

    @Test
    func equatableSemantics() {
        testEquatableSemantics(
            equal: [
                (ConfigError.emptyRoot, ConfigError.emptyRoot),
                (
                    ConfigError.unsupportedLanguage("en"),
                    ConfigError.unsupportedLanguage("en")
                ),
            ],
            notEqual: [
                (ConfigError.emptyRoot, ConfigError.missingRoot),
                (
                    ConfigError.unsupportedLanguage("en"),
                    ConfigError.unsupportedLanguage("de")
                ),
            ]
        )
    }
}
