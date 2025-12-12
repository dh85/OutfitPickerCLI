import Foundation

/// Supported languages for outfit picker localization.
///
/// Contains ISO 639-1 language codes for supported localizations.
public enum SupportedLanguage: String, CaseIterable, Sendable, Equatable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case dutch = "nl"
    case russian = "ru"
    case japanese = "ja"
    case chinese = "zh"
    case korean = "ko"
    case arabic = "ar"
    case hindi = "hi"
    case norwegian = "no"
    case swedish = "sv"
    case finnish = "fi"
    case danish = "da"
    case polish = "pl"
    case hungarian = "hu"
    case croatian = "hr"
    case serbian = "sr"
    case romanian = "ro"
    case greek = "el"
    case bulgarian = "bg"
    case turkish = "tr"
    case lithuanian = "lt"
    case latvian = "lv"
    case estonian = "et"
    case icelandic = "is"
    case catalan = "ca"
    case ukrainian = "uk"
    case maltese = "mt"
    case slovak = "sk"
    case czech = "cs"
    case slovenian = "sl"
    case bengali = "bn"
    case vietnamese = "vi"
    case thai = "th"
    case hebrew = "he"
    case indonesian = "id"
    case malay = "ms"
    case tamil = "ta"
    case telugu = "te"
    case gujarati = "gu"
    case punjabi = "pa"
    case urdu = "ur"
    case swahili = "sw"
    case amharic = "am"
    case yoruba = "yo"
    case zulu = "zu"
    case afrikaans = "af"

    /// ISO 639-1 language code
    public var code: String { rawValue }
}

/// Builder for creating validated Config instances using a fluent API.
///
/// ConfigBuilder provides a type-safe way to construct configurations with
/// method chaining and automatic validation. All errors are mapped to
/// OutfitPickerError for consistent handling.
///
/// Example:
/// ```swift
/// let config = try ConfigBuilder()
///     .rootDirectory("/Users/john/outfits")
///     .language(.spanish)
///     .exclude("formal", "winter")
///     .build()
/// ```
public final class ConfigBuilder: @unchecked Sendable {
    private var rootPath: String?
    private var language: SupportedLanguage = .english
    private var excludedCategories = Set<String>()
    private var knownCategories = Set<String>()

    /// Creates a new ConfigBuilder with default settings
    public init() {}

    // MARK: - Configuration Methods

    /// Sets the root directory path for outfit files
    @discardableResult
    public func rootDirectory(_ path: String) -> Self {
        self.rootPath = path
        return self
    }

    /// Sets the language for localization
    @discardableResult
    public func language(_ language: SupportedLanguage) -> Self {
        self.language = language
        return self
    }

    // MARK: - Category Exclusion

    /// Excludes multiple categories from outfit selection
    @discardableResult
    public func exclude(categories: Set<String>) -> Self {
        self.excludedCategories.formUnion(categories)
        return self
    }

    /// Excludes a single category from outfit selection
    @discardableResult
    public func exclude(category: String) -> Self {
        self.excludedCategories.insert(category)
        return self
    }

    /// Excludes multiple categories using variadic parameters
    @discardableResult
    public func exclude(_ categories: String...) -> Self {
        let cleaned = categories.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.excludedCategories.formUnion(cleaned.filter { !$0.isEmpty })
        return self
    }

    // MARK: - Known Categories

    /// Sets known categories from a dictionary of category states
    @discardableResult
    public func knownCategories(_ categories: [String: CategoryState]) -> Self {
        self.knownCategories = Set(categories.keys)
        return self
    }

    /// Sets known categories from any sequence of strings
    @discardableResult
    public func knownCategories<S: Sequence>(_ categories: S) -> Self
    where S.Element == String {
        self.knownCategories = Set(categories)
        return self
    }

    /// Includes multiple categories in the known categories set
    @discardableResult
    public func include(categories: Set<String>) -> Self {
        self.knownCategories.formUnion(categories)
        return self
    }

    /// Includes a single category in the known categories set
    @discardableResult
    public func include(category: String) -> Self {
        self.knownCategories.insert(category)
        return self
    }

    /// Includes multiple categories using variadic parameters
    @discardableResult
    public func include(_ categories: String...) -> Self {
        self.knownCategories.formUnion(categories)
        return self
    }

    // MARK: - Build Configuration

    /// Creates a validated Config instance from the current builder state
    /// - Throws: `OutfitPickerError` if validation fails or no root directory was set
    /// - Returns: A validated Config instance
    public func build() throws -> Config {
        guard let rootPath else {
            throw OutfitPickerError.invalidInput(
                "Root directory must be set before building config")
        }

        return try Config(
            root: rootPath,
            language: language.code,
            excludedCategories: excludedCategories,
            knownCategories: knownCategories
        )
    }
}
