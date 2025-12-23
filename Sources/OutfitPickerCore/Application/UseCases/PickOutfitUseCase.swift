import Foundation

public struct PickOutfitRequest {
    public let categoryName: String

    public init(categoryName: String) {
        self.categoryName = categoryName
    }
}

public struct PickOutfitUseCase: Sendable {
    private let repository: CategoryRepositoryProtocol
    private let configService: ConfigServiceProtocol
    private let cacheService: CacheServiceProtocol

    public init(
        repository: CategoryRepositoryProtocol,
        configService: ConfigServiceProtocol,
        cacheService: CacheServiceProtocol
    ) {
        self.repository = repository
        self.configService = configService
        self.cacheService = cacheService
    }

    public func execute(request: PickOutfitRequest) async throws -> OutfitReference? {
        try BusinessRules.validateCategoryName(request.categoryName)

        let config = try configService.load()
        let cache = try cacheService.load()

        let categoryPath = (config.root as NSString).appendingPathComponent(request.categoryName)
        let files = try await repository.getOutfits(in: categoryPath)

        guard !files.isEmpty else { return nil }

        let categoryCache =
            cache.categories[request.categoryName]
            ?? CategoryCache(totalOutfits: files.count)

        let wornCount = categoryCache.wornOutfits.count
        let totalCount = files.count

        var pool: [FileEntry]

        if BusinessRules.shouldResetRotation(wornCount: wornCount, totalCount: totalCount) {
            pool = files

            var newCache = cache
            newCache.categories[request.categoryName] = CategoryCache(totalOutfits: files.count)
            try cacheService.save(newCache)
        } else {
            pool = BusinessRules.filterAvailableOutfits(
                from: files,
                wornOutfits: categoryCache.wornOutfits
            )
        }

        if pool.isEmpty {
            pool = files
        }

        guard let selectedFile = OutfitSelection.selectRandom(from: pool) else {
            return nil
        }

        return OutfitReference(
            fileName: selectedFile.fileName,
            category: CategoryReference(name: request.categoryName, path: categoryPath)
        )
    }
}
