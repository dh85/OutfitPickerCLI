import Foundation

/// Centralized business rules and constants for the OutfitPicker application.
public struct BusinessRules {

    // MARK: - File System Rules

    /// File extension for outfit files
    public static let outfitFileExtension = "avatar"

    /// Default language code
    public static let defaultLanguage = "en"

    // MARK: - Performance Rules

    /// Maximum time allowed for concurrent scanning operations (in seconds)
    public static let maxScanningDuration: TimeInterval = 1.0

    // MARK: - Validation Rules

    /// Validates if a string represents a valid outfit file
    public static func isValidOutfitFile(_ fileName: String) -> Bool {
        return fileName.lowercased().hasSuffix(".\(outfitFileExtension)")
    }

    /// Validates if a category name is valid
    public static func isValidCategoryName(_ name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Validates if an outfit filename is valid
    public static func isValidOutfitFileName(_ fileName: String) -> Bool {
        return !fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Rotation Rules

    /// Determines if a category rotation should be reset based on worn count
    public static func shouldResetRotation(wornCount: Int, totalCount: Int) -> Bool {
        return wornCount >= totalCount
    }

    /// Calculates progress percentage for a category
    public static func calculateProgress(wornCount: Int, totalCount: Int) -> Double {
        guard totalCount > 0 else { return 1.0 }
        return Double(wornCount) / Double(totalCount)
    }

    /// Determines if rotation is complete
    public static func isRotationComplete(wornCount: Int, totalCount: Int) -> Bool {
        return wornCount >= totalCount
    }

    // MARK: - Validation Rules

    /// Validates category name and throws if invalid
    public static func validateCategoryName(_ categoryName: String) throws {
        guard isValidCategoryName(categoryName) else {
            throw OutfitPickerError.invalidInput("Category name cannot be empty")
        }
    }

    /// Validates outfit and throws if invalid
    public static func validateOutfit(_ outfit: OutfitReference) throws {
        guard isValidOutfitFileName(outfit.fileName) else {
            throw OutfitPickerError.invalidInput("Outfit filename cannot be empty")
        }
        try validateCategoryName(outfit.category.name)
    }

    /// Generates status text for category progress
    public static func generateStatusText(wornCount: Int, totalCount: Int) -> String {
        return "\(wornCount) of \(totalCount) outfits worn"
    }

    // MARK: - Category State Rules

    /// Determines if a category is empty based on avatar and all files
    public static func isCategoryEmpty(avatarFiles: [FileEntry], allFiles: [URL]) -> Bool {
        return avatarFiles.isEmpty && allFiles.isEmpty
    }

    /// Determines if a category has no avatar files but has other files
    public static func hasNoAvatarFiles(avatarFiles: [FileEntry], allFiles: [URL]) -> Bool {
        return avatarFiles.isEmpty && !allFiles.isEmpty
    }

    // MARK: - File Filtering Rules

    /// Filters files to only include valid outfit files
    public static func filterOutfitFiles(from urls: [URL]) -> [FileEntry] {
        return urls.compactMap { fileURL -> FileEntry? in
            guard !fileURL.hasDirectoryPath,
                isValidOutfitFile(fileURL.lastPathComponent)
            else {
                return nil
            }
            return FileEntry(filePath: fileURL.path(percentEncoded: false))
        }.sorted { $0.fileName < $1.fileName }
    }

    /// Filters available outfits based on worn status
    public static func filterAvailableOutfits(
        from files: [FileEntry],
        wornOutfits: Set<String>
    ) -> [FileEntry] {
        return files.filter { !wornOutfits.contains($0.fileName) }
    }
}
