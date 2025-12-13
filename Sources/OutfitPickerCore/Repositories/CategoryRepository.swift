import Foundation

public protocol CategoryRepositoryProtocol: Sendable {
    func getCategories(in rootPath: String, excludedCategories: Set<String>) async throws
        -> [CategoryInfo]
    func getOutfits(in categoryPath: String) async throws -> [FileEntry]
    func invalidateCache() async
}

public struct CategoryRepository: CategoryRepositoryProtocol {
    private let categoryScanner: CategoryScannerProtocol
    private let cacheManager: CacheManagerProtocol

    public init(
        categoryScanner: CategoryScannerProtocol,
        cacheManager: CacheManagerProtocol = CacheManager()
    ) {
        self.categoryScanner = categoryScanner
        self.cacheManager = cacheManager
    }

    public func getCategories(in rootPath: String, excludedCategories: Set<String>) async throws
        -> [CategoryInfo]
    {
        if let cached = await cacheManager.getCachedCategoryInfo(for: rootPath) {
            return cached
        }

        let categories = try await categoryScanner.scanCategories(
            in: rootPath, excludedCategories: excludedCategories)
        await cacheManager.setCachedCategoryInfo(categories, for: rootPath)
        return categories
    }

    public func getOutfits(in categoryPath: String) async throws -> [FileEntry] {
        if let cached = await cacheManager.getCachedOutfits(for: categoryPath) {
            return cached
        }

        let outfits = try await categoryScanner.getOutfits(in: categoryPath)
        await cacheManager.setCachedOutfits(outfits, for: categoryPath)
        return outfits
    }

    public func invalidateCache() async {
        await cacheManager.invalidateCache()
    }
}
