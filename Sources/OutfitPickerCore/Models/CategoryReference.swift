import Foundation

/// Reference to a category directory containing outfit files.
///
/// CategoryReference provides a lightweight way to identify and reference
/// a category without loading all its outfit files.
public struct CategoryReference: Sendable, Hashable, CustomStringConvertible {
    /// Display name of the category
    public let name: String
    /// Full filesystem path to the category directory
    public let path: String

    internal init(name: String, path: String) {
        self.name = name
        self.path = path
    }

    public var description: String { name }
}

/// Reference to a specific outfit file within a category.
///
/// OutfitReference combines a filename with its category context,
/// providing complete information needed to locate and display an outfit.
public struct OutfitReference: Sendable, Hashable, CustomStringConvertible {
    /// Name of the outfit file
    public let fileName: String
    /// Category containing this outfit
    public let category: CategoryReference

    internal init(fileName: String, category: CategoryReference) {
        self.fileName = fileName
        self.category = category
    }

    /// Complete filesystem path to the outfit file
    public var filePath: String {
        URL(filePath: category.path, directoryHint: .isDirectory)
            .appending(path: fileName, directoryHint: .notDirectory)
            .path(percentEncoded: false)
    }

    public var description: String { "\(fileName) in \(category.name)" }
}

/// Specifies the scope for outfit selection operations.
///
/// SelectionTarget allows operations to target specific categories,
/// all categories, or a custom set of categories.
public enum SelectionTarget: Sendable, Equatable {
    /// Select from a single category
    case category(CategoryReference)
    /// Select from all available categories
    case allCategories
    /// Select from a specific set of categories
    case categories([CategoryReference])
}

/// Tracks rotation progress for a specific category.
///
/// RotationProgress provides information about how many outfits have been
/// worn in the current rotation cycle and calculates completion status.
public struct RotationProgress: Sendable, Equatable {
    /// Category being tracked
    public let category: CategoryReference
    /// Number of outfits worn in current rotation
    public let wornCount: Int
    /// Total number of outfits in the category
    public let totalOutfitCount: Int
    /// Whether the rotation cycle is complete
    public let isComplete: Bool

    /// Progress as a value between 0.0 and 1.0
    public var progress: Double {
        totalOutfitCount > 0
            ? Double(wornCount) / Double(totalOutfitCount) : 1.0
    }

    /// Number of outfits available for selection
    public var availableCount: Int {
        isComplete ? totalOutfitCount : totalOutfitCount - wornCount
    }
}
