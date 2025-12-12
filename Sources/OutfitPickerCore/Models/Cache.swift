import Foundation

public struct CategoryCache: Codable, Equatable, Sendable {
    public let wornOutfits: Set<String>
    public let totalOutfits: Int
    public let lastUpdated: Date

    public init(
        wornOutfits: Set<String> = [],
        totalOutfits: Int,
        lastUpdated: Date = Date()
    ) {
        self.wornOutfits = wornOutfits
        self.totalOutfits = totalOutfits
        self.lastUpdated = lastUpdated
    }

    public var isRotationComplete: Bool {
        wornOutfits.count >= totalOutfits
    }

    public var rotationProgress: Double {
        guard totalOutfits > 0 else { return 1.0 }
        return Double(wornOutfits.count) / Double(totalOutfits)
    }

    public var remainingOutfits: Int {
        max(0, totalOutfits - wornOutfits.count)
    }

    public func adding(_ fileName: String) -> CategoryCache {
        CategoryCache(
            wornOutfits: wornOutfits.union([fileName]),
            totalOutfits: totalOutfits,
            lastUpdated: Date()
        )
    }

    public func reset() -> CategoryCache {
        CategoryCache(totalOutfits: totalOutfits)
    }
}

public struct OutfitCache: Codable, Equatable {
    public let categories: [String: CategoryCache]
    public let version: Int
    public let createdAt: Date

    public init(
        categories: [String: CategoryCache] = [:],
        version: Int = 1,
        createdAt: Date = Date()
    ) {
        self.categories = categories
        self.version = version
        self.createdAt = createdAt
    }

    public func updating(category path: String, with cache: CategoryCache) -> OutfitCache {
        var updatedCategories = categories
        updatedCategories[path] = cache
        return OutfitCache(
            categories: updatedCategories,
            version: version,
            createdAt: createdAt
        )
    }

    public func resetAll() -> OutfitCache {
        let resetCategories = categories.mapValues { $0.reset() }
        return OutfitCache(
            categories: resetCategories,
            version: version,
            createdAt: createdAt
        )
    }

    public func removing(category path: String) -> OutfitCache {
        var updatedCategories = categories
        updatedCategories.removeValue(forKey: path)
        return OutfitCache(
            categories: updatedCategories,
            version: version,
            createdAt: createdAt
        )
    }

    public func resetting(category path: String) -> OutfitCache? {
        guard let categoryCache = categories[path] else { return nil }
        return updating(category: path, with: categoryCache.reset())
    }
}
