import Foundation

public protocol CacheManagerProtocol: Sendable {
    func getCachedCategoryInfo(for rootPath: String) async -> [CategoryInfo]?
    func setCachedCategoryInfo(_ categoryInfos: [CategoryInfo], for rootPath: String) async
    func getCachedOutfits(for categoryPath: String) async -> [FileEntry]?
    func setCachedOutfits(_ outfits: [FileEntry], for categoryPath: String) async
    func invalidateCache() async
}

public actor CacheManager: CacheManagerProtocol {
    private var categoryInfoCache: [String: [CategoryInfo]] = [:]
    private var outfitsCache: [String: [FileEntry]] = [:]

    public init() {}

    public func getCachedCategoryInfo(for rootPath: String) -> [CategoryInfo]? {
        return categoryInfoCache[rootPath]
    }

    public func setCachedCategoryInfo(_ categoryInfos: [CategoryInfo], for rootPath: String) {
        categoryInfoCache[rootPath] = categoryInfos
    }

    public func getCachedOutfits(for categoryPath: String) -> [FileEntry]? {
        return outfitsCache[categoryPath]
    }

    public func setCachedOutfits(_ outfits: [FileEntry], for categoryPath: String) {
        outfitsCache[categoryPath] = outfits
    }

    public func invalidateCache() {
        categoryInfoCache.removeAll()
        outfitsCache.removeAll()
    }
}
