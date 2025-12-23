import Foundation

/// Represents the current state of a category directory.
///
/// CategoryState indicates whether a category contains usable outfit files,
/// is empty, or has been excluded by the user.
public enum CategoryState: Codable, Sendable, Equatable {
    /// Category contains outfit files that can be used
    case hasOutfits
    /// Category directory exists but contains no files
    case empty
    /// Category contains files but no .avatar files
    case noAvatarFiles
    /// Category has been excluded by user configuration
    case userExcluded
}

/// Combines a category with its current state information.
///
/// CategoryInfo provides complete information about a category including
/// its reference and current usability state.
public struct CategoryInfo: Sendable, Equatable {
    /// Reference to the category
    public let category: CategoryReference
    /// Current state of the category
    public let state: CategoryState
    /// Number of outfit files in the category
    public let outfitCount: Int

    public init(category: CategoryReference, state: CategoryState, outfitCount: Int) {
        self.category = category
        self.state = state
        self.outfitCount = outfitCount
    }
}
