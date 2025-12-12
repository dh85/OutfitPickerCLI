import Foundation

/// Builder for creating complex batch operations with a fluent API.
///
/// BatchOperationBuilder allows you to chain multiple operations together
/// and execute them efficiently in a single call.
///
/// ## Example
/// ```swift
/// try await picker.batch()
///     .wear(outfit1, outfit2)
///     .reset("summer", "vacation")
///     .execute()
/// ```
public struct BatchOperationBuilder: Sendable {
    private let picker: OutfitPicker
    private var outfitsToWear: [OutfitReference] = []
    private var categoriesToReset: [String] = []

    internal init(picker: OutfitPicker) {
        self.picker = picker
    }

    /// Adds outfits to be marked as worn.
    @discardableResult
    public func wear(_ outfits: OutfitReference...) -> BatchOperationBuilder {
        var builder = self
        builder.outfitsToWear.append(contentsOf: outfits)
        return builder
    }

    /// Adds outfits to be marked as worn from an array.
    @discardableResult
    public func wear(_ outfits: [OutfitReference]) -> BatchOperationBuilder {
        var builder = self
        builder.outfitsToWear.append(contentsOf: outfits)
        return builder
    }

    /// Adds categories to be reset.
    @discardableResult
    public func reset(_ categories: String...) -> BatchOperationBuilder {
        var builder = self
        builder.categoriesToReset.append(contentsOf: categories)
        return builder
    }

    /// Adds categories to be reset from an array of strings.
    @discardableResult
    public func resetCategories(_ categories: [String]) -> BatchOperationBuilder {
        var builder = self
        builder.categoriesToReset.append(contentsOf: categories)
        return builder
    }

    /// Adds CategoryReference instances to be reset.
    @discardableResult
    public func reset(_ categories: [CategoryReference]) -> BatchOperationBuilder {
        var builder = self
        builder.categoriesToReset.append(contentsOf: categories.map { $0.name })
        return builder
    }

    /// Executes all batched operations.
    /// - Returns: Summary of operations performed
    /// - Throws: `OutfitPickerError` if any operation fails
    public func execute() async throws -> BatchOperationResult {
        var wornCount = 0
        var resetCount = 0

        if !outfitsToWear.isEmpty {
            try await picker.wearOutfits(outfitsToWear)
            wornCount = outfitsToWear.count
        }

        if !categoriesToReset.isEmpty {
            try await picker.resetCategories(categoriesToReset)
            resetCount = categoriesToReset.count
        }

        return BatchOperationResult(
            outfitsWorn: wornCount,
            categoriesReset: resetCount
        )
    }
}

/// Result of batch operations execution.
public struct BatchOperationResult {
    /// Number of outfits marked as worn
    public let outfitsWorn: Int
    /// Number of categories reset
    public let categoriesReset: Int

    /// Total number of operations performed
    public var totalOperations: Int {
        outfitsWorn + categoriesReset
    }

    /// Human-readable summary of operations
    public var summary: String {
        var parts: [String] = []
        if outfitsWorn > 0 {
            parts.append("\(outfitsWorn) outfits worn")
        }
        if categoriesReset > 0 {
            parts.append("\(categoriesReset) categories reset")
        }
        return parts.isEmpty ? "No operations performed" : parts.joined(separator: ", ")
    }
}

extension OutfitPicker {
    /// Creates a batch operation builder for chaining multiple operations.
    ///
    /// Use this to efficiently perform multiple operations in a single call.
    ///
    /// ## Example
    /// ```swift
    /// let result = try await picker.batch()
    ///     .wear(outfit1, outfit2, outfit3)
    ///     .reset("summer", "vacation")
    ///     .execute()
    ///
    /// print(result.summary) // "3 outfits worn, 2 categories reset"
    /// ```
    public func batch() -> BatchOperationBuilder {
        BatchOperationBuilder(picker: self)
    }
}
