import Foundation

/// Fluent API for chaining outfit operations.
public struct OutfitSelection: Sendable {
    let outfit: OutfitReference
    let picker: OutfitPicker

    /// Marks this outfit as worn and returns the picker for further operations.
    @discardableResult
    public func wear() async throws -> OutfitPicker {
        try await picker.wearOutfit(outfit)
        return picker
    }

    /// Gets alternatives from the same category, excluding this outfit.
    public func alternatives() async throws -> [OutfitReference] {
        let all = try await picker.showAllOutfits(from: outfit.category.name)
        return all.filter { $0.fileName != outfit.fileName }
    }

    /// Checks if this outfit has been worn before.
    public func isWorn() async throws -> Bool {
        try await picker.isOutfitWorn(outfit.fileName, in: outfit.category.name)
    }
}

extension OutfitPicker {
    /// Fluent API for selecting and working with outfits.
    ///
    /// Enables method chaining for common workflows like select-and-wear.
    ///
    /// ## Example
    /// ```swift
    /// try await picker.select(from: "casual")?.wear()
    ///
    /// let alternatives = try await picker.select(from: "work")?
    ///     .alternatives()
    /// ```
    public func select(from categoryName: String) async throws -> OutfitSelection? {
        guard let outfit = try await showRandomOutfit(from: categoryName) else {
            return nil
        }
        return OutfitSelection(outfit: outfit, picker: self)
    }

    /// Type-safe fluent selection using CategoryReference.
    public func select(from category: CategoryReference) async throws -> OutfitSelection? {
        return try await select(from: category.name)
    }
}
