import Foundation

/// Configuration for outfit picker application.
///
/// Stores the root directory path for outfit files and optional language preference.
/// Configurations are automatically validated during creation to ensure security.
/// All validation errors are mapped to OutfitPickerError for consistent handling.
///
/// Example:
/// ```swift
/// let config = try Config(root: "/Users/john/outfits", language: "en")
/// ```
public struct Config: Codable, Sendable, Equatable {
    /// Root directory path containing outfit files
    public let root: String
    /// Language code for localization (e.g., "en", "es", "fr")
    public let language: String?
    /// Categories excluded from outfit selection
    public let excludedCategories: Set<String>
    /// Categories discovered in the filesystem
    public let knownCategories: Set<String>
    /// Files tracked per category for change detection
    public let knownCategoryFiles: [String: Set<String>]

    /// Creates and validates a new configuration.
    ///
    /// Performs comprehensive validation including:
    /// - Path security checks (traversal, restricted directories, symlinks)
    /// - Language code validation
    /// - Input sanitization
    ///
    /// - Parameters:
    ///   - root: Path to the root directory containing outfit files
    ///   - language: Optional ISO 639-1 language code
    ///   - excludedCategories: Categories to exclude from selection
    ///   - knownCategories: Categories discovered in filesystem
    ///   - knownCategoryFiles: Files tracked per category
    /// - Throws: `OutfitPickerError` if validation fails
    public init(
        root: String,
        language: String? = nil,
        excludedCategories: Set<String> = [],
        knownCategories: Set<String> = [],
        knownCategoryFiles: [String: Set<String>] = [:]
    ) throws {
        do {
            guard !root.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                throw OutfitPickerError.invalidInput("Root directory cannot be empty")
            }

            try PathValidator.validate(root)
            try LanguageValidator.validate(language)

            self.root = root
            self.language = language ?? "en"
            self.excludedCategories = excludedCategories
            self.knownCategories = knownCategories
            self.knownCategoryFiles = knownCategoryFiles
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }
}
