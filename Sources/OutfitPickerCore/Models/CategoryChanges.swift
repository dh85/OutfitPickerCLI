import Foundation

/// Represents changes detected in outfit categories and their files.
///
/// CategoryChanges tracks all types of modifications that can occur in the outfit
/// directory structure, including new/deleted categories and file changes within categories.
///
/// Example:
/// ```swift
/// let changes = CategoryChanges(
///     newCategories: ["summer"],
///     deletedCategories: ["winter"],
///     addedFiles: ["casual": ["new-outfit.avatar"]]
/// )
/// print(changes.hasChanges) // true
/// ```
public struct CategoryChanges: Sendable, Equatable {
    /// Categories that were newly created
    public let newCategories: Set<String>
    /// Categories that were removed
    public let deletedCategories: Set<String>
    /// Categories that had file changes
    public let changedCategories: Set<String>
    /// Files added per category
    public let addedFiles: [String: Set<String>]
    /// Files deleted per category
    public let deletedFiles: [String: Set<String>]

    public init(
        newCategories: Set<String> = [],
        deletedCategories: Set<String> = [],
        changedCategories: Set<String> = [],
        addedFiles: [String: Set<String>] = [:],
        deletedFiles: [String: Set<String>] = [:]
    ) {
        self.newCategories = newCategories
        self.deletedCategories = deletedCategories
        self.changedCategories = changedCategories
        self.addedFiles = addedFiles
        self.deletedFiles = deletedFiles
    }

    /// Whether any changes were detected
    public var hasChanges: Bool {
        !isEmpty
    }

    /// Whether no changes were detected
    public var isEmpty: Bool {
        newCategories.isEmpty && deletedCategories.isEmpty
            && changedCategories.isEmpty
            && addedFiles.isEmpty && deletedFiles.isEmpty
    }
}
