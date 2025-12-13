import Foundation

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
