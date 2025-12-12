import Foundation

/// Top-level errors for outfit picker operations.
///
/// These are the primary errors that consumers will encounter when using
/// the outfit picker library. All lower-level errors are mapped to these cases.
public enum OutfitPickerError: Error, LocalizedError, Equatable {
    /// Configuration file could not be found or loaded.
    case configurationNotFound
    /// Requested outfit category does not exist.
    case categoryNotFound
    /// No outfit files available in the specified category or location.
    case noOutfitsAvailable
    /// File system operation failed (permissions, missing files, etc.).
    case fileSystemError
    /// Cache operation failed (corruption, encoding/decoding issues).
    case cacheError
    /// Configuration contains invalid settings or paths.
    case invalidConfiguration
    /// User provided invalid input parameters.
    case invalidInput(String)
    /// All outfits in the category have been worn and the rotation has been reset.
    case rotationCompleted(category: String)

    public var errorDescription: String? {
        switch self {
        case .configurationNotFound: "Configuration not found"
        case .categoryNotFound: "Category not found"
        case .noOutfitsAvailable: "No outfits available"
        case .fileSystemError: "File system error"
        case .cacheError: "Cache error"
        case .invalidConfiguration: "Invalid configuration"
        case .invalidInput(let message): "Invalid input: \(message)"
        case .rotationCompleted(let category): "All outfits in '\(category)' have been worn. Category has been reset."
        }
    }
}

extension OutfitPickerError {
    /// Maps lower-level errors to top-level OutfitPickerError cases.
    ///
    /// This method converts internal errors (ConfigError, FileSystemError, etc.)
    /// into user-facing OutfitPickerError cases for consistent error handling.
    ///
    /// - Parameter error: The error to map
    /// - Returns: Corresponding OutfitPickerError case
    public static func from(_ error: Error) -> OutfitPickerError {
        switch error {
        case let outfitError as OutfitPickerError:
            return outfitError
        case is ConfigError:
            return .invalidConfiguration
        case is CacheError, is StorageError:
            return .cacheError
        case is FileSystemError:
            return .fileSystemError
        default:
            return .fileSystemError
        }
    }
}

/// Convenience type alias for Result with OutfitPickerError.
///
/// Use this for consistent error handling across outfit picker operations:
/// ```swift
/// let result: OutfitPickerResult<OutfitReference> = outfitPicker.showRandomOutfit()
/// switch result {
/// case .success(let outfit):
///     // Handle successful outfit selection
/// case .failure(let error):
///     // Handle error cases
/// }
/// ```
public typealias OutfitPickerResult<T> = Result<T, OutfitPickerError>
