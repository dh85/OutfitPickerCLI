import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct ConfigTests {

    // MARK: - Happy path

    @Test("Valid config constructs and defaults language to 'en' when nil")
    func validConfig_defaultsLanguage() throws {
        let sut = try makeSUT(root: "/valid/path", language: nil)
        #expect(sut.root == "/valid/path")
        #expect(sut.language == "en")
        #expect(sut.excludedCategories.isEmpty)
        #expect(sut.knownCategories.isEmpty)
    }

    @Test(
        "Valid paths",
        arguments: [
            "/valid/path",
            "/home/user/outfits",
            "./outfits",
            "outfits/casual",
            "/Users/me/Documents/outfits",
            "relative/path/to/outfits",
        ]
    )
    func validPaths_construct(root: String) throws {
        _ = try makeSUT(root: root)
    }

    // MARK: - Validation: root

    @Test("Empty root throws", arguments: ["", "   ", "\t", "\n", " \t \n "])
    func emptyRootThrows(root: String) {
        expectOutfitPickerError(.invalidInput("Root directory cannot be empty"), for: root)
    }

    @Test("Path too long throws (>4096 chars)")
    func pathTooLongThrows() {
        expectOutfitPickerError(
            .invalidConfiguration,
            for: String(repeating: "a", count: 4097)
        )
    }

    @Test("Max path length allowed (4096 chars)")
    func maxPathLengthAllowed() throws {
        _ = try makeSUT(root: String(repeating: "a", count: 4096))
    }

    @Test(
        "Path traversal throws",
        arguments: [
            "/path/../traversal",
            "../etc/passwd",
            "/home/user/../../../etc",
            "./../../secret",
            "path/.//../other",
            "/valid/path/../../etc",
            "./path/../../../root",
            "path///../system",
            "/path/subdir/../../..",
        ]
    )
    func pathTraversalThrows(root: String) {
        expectOutfitPickerError(.invalidConfiguration, for: root)
    }

    @Test(
        "Restricted paths throw",
        arguments: [
            "/etc/passwd",
            "/usr/bin/sudo",
            "/bin/bash",
            "/sbin/init",
            "/System/Library",
            "/private/etc",
            "/var/log",
            "/root/.ssh",
        ]
    )
    func restrictedPathsThrow(root: String) {
        expectOutfitPickerError(.invalidConfiguration, for: root)
    }

    @Test(
        "Invalid characters throw",
        arguments: [
            "/path/with\0null",
            "/path/with\u{0001}control",
            "/path/with\u{0008}backspace",
            "/path/with\u{007F}delete",
        ]
    )
    func invalidCharactersThrow(root: String) {
        expectOutfitPickerError(.invalidConfiguration, for: root)
    }

    @Test(
        "Valid special characters are accepted",
        arguments: [
            "/path/with spaces",
            "/path/with-dashes",
            "/path/with_underscores",
            "/path/with.dots",
            "/path/with(parentheses)",
        ]
    )
    func validSpecialCharactersAllowed(root: String) throws {
        _ = try makeSUT(root: root)
    }

    #if os(Windows)
        @Test(
            "Windows valid paths",
            arguments: [
                "C:\\Users\\John\\outfits",
                "D:/outfits/casual",
                "\\\\server\\share\\outfits",
                "C:\\outfits",
            ]
        )
        func windowsValidPaths(root: String) throws {
            _ = try makeSUT(root: root)
        }

        @Test(
            "Windows restricted paths throw",
            arguments: [
                "C:\\Windows\\System32",
                "C:\\Program Files",
                "C:\\Users\\Administrator",
                "\\\\localhost\\C$",
            ]
        )
        func windowsRestrictedPathsThrow(root: String) {
            expectOutfitPickerError(.invalidConfiguration, for: root)
        }
    #endif

    // MARK: - Validation: language

    @Test("Unsupported language throws")
    func invalidLanguageThrows() {
        #expect(throws: OutfitPickerError.invalidConfiguration) {
            _ = try makeSUT(language: "invalid")
        }
    }

    @Test(
        "Supported languages pass",
        arguments: [
            "en", "es", "fr", "de", "it", "pt", "nl", "ru", "ja", "zh", "ko",
            "ar", "hi", "no", "sv", "fi", "da", "pl", "hu", "hr", "sr", "ro",
            "el", "tr", "bg", "lt", "lv", "et", "is", "mt", "ca", "uk", "sk",
            "cs", "sl", "bn", "vi", "th", "he", "id", "ms", "ta", "te", "gu",
            "pa", "ur", "sw", "am", "yo", "zu", "af",
        ]
    )
    func supportedLanguages(language: String) throws {
        _ = try makeSUT(language: language)
    }

    // MARK: - JSON: encoding / decoding

    @Test("JSON encodes expected keys")
    func jsonEncoding() throws {
        let sut = try makeSUT(root: "/test/path", language: "en")
        let json = try encodeToJSON(sut)

        #expect(json["root"] as? String == "/test/path")
        #expect(json["language"] as? String == "en")
        #expect(json.keys.contains("excludedCategories"))
        #expect(json.keys.contains("knownCategories"))
    }

    @Test("JSON decoding populates all fields")
    func jsonDecoding() throws {
        let json = """
            {
                "root": "/test/path",
                "language": "es",
                "excludedCategories": ["downloads"],
                "knownCategories": ["casual", "formal"],
                "knownCategoryFiles": {
                    "casual": ["a.avatar", "b.avatar"],
                    "formal": ["dress1.avatar"]
                }
            }
            """
        let config = try decodeConfig(from: json)

        #expect(config.root == "/test/path")
        #expect(config.language == "es")
        #expect(config.excludedCategories == ["downloads"])
        #expect(config.knownCategories == ["casual", "formal"])
        #expect(config.knownCategoryFiles.count == 2)
        #expect(
            config.knownCategoryFiles["casual"] == ["a.avatar", "b.avatar"]
        )
        #expect(config.knownCategoryFiles["formal"] == ["dress1.avatar"])
    }

    @Test(
        "JSON decoding without language leaves it nil (Codable bypasses init)"
    )
    func jsonDecodingWithoutLanguage() throws {
        let json = """
            {
                "root": "/test/path",
                "excludedCategories": [],
                "knownCategories": [],
                "knownCategoryFiles": {}
            }
            """
        let decoded = try decodeConfig(from: json)

        #expect(decoded.root == "/test/path")
        #expect(decoded.language == nil)
    }

    @Test("Equatable roundtrip")
    func equatableRoundTrip() throws {
        let a = try Config(
            root: "/r",
            language: "en",
            excludedCategories: ["x"],
            knownCategories: ["y"]
        )
        let b = try Config(
            root: "/r",
            language: "en",
            excludedCategories: ["x"],
            knownCategories: ["y"]
        )
        #expect(a == b)
    }

    @Test("Non-ASCII characters in path throw invalidCharacters")
    func nonAsciiCharactersThrow() {
        let badPaths = ["/path/withéaccent", "/path/with😀emoji"]
        for path in badPaths {
            expectOutfitPickerError(.invalidConfiguration, for: path)
        }
    }

    @Test("Over-normalised path without '..' throws pathTraversalNotAllowed")
    func overNormalisedPathThrowsTraversal() {
        expectOutfitPickerError(.invalidConfiguration, for: "/a/././././b")
    }

    // MARK: - Helpers

    private func makeSUT(root: String = "/valid/path", language: String? = nil)
        throws -> Config
    {
        try Config(root: root, language: language)
    }

    private func expectOutfitPickerError(_ error: OutfitPickerError, for root: String) {
        #expect(throws: error) {
            _ = try makeSUT(root: root)
        }
    }

    private func encodeToJSON(_ config: Config) throws -> [String: Any] {
        let data = try JSONEncoder().encode(config)
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    private func decodeConfig(from json: String) throws -> Config {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(Config.self, from: data)
    }
}
