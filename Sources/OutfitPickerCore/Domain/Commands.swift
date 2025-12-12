import Foundation

/// Command for wearing an outfit
public struct WearOutfitCommand {
    public let outfit: OutfitReference

    public init(outfit: OutfitReference) {
        self.outfit = outfit
    }
}

/// Command for resetting category rotation
public struct ResetCategoryCommand {
    public let categoryName: String

    public init(categoryName: String) {
        self.categoryName = categoryName
    }
}

/// Command for resetting all categories
public struct ResetAllCategoriesCommand {
    public init() {}
}
