import Foundation
import OutfitPickerCore

public struct FakeCacheManager: CacheManagerProtocol {
    private var categoryInfoCache: [String: [CategoryInfo]]
    private var outfitsCache: [String: [FileEntry]]

    public init(
        categoryInfoCache: [String: [CategoryInfo]] = [:], outfitsCache: [String: [FileEntry]] = [:]
    ) {
        self.categoryInfoCache = categoryInfoCache
        self.outfitsCache = outfitsCache
    }

    public func getCachedCategoryInfo(for rootPath: String) async -> [CategoryInfo]? {
        return categoryInfoCache[rootPath]
    }

    public func setCachedCategoryInfo(_ categoryInfos: [CategoryInfo], for rootPath: String) async {
        // No-op for fake
    }

    public func getCachedOutfits(for categoryPath: String) async -> [FileEntry]? {
        return outfitsCache[categoryPath]
    }

    public func setCachedOutfits(_ outfits: [FileEntry], for categoryPath: String) async {
        // No-op for fake
    }

    public func invalidateCache() async {
        // No-op for fake
    }
}
