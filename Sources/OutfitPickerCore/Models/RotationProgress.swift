import Foundation

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
