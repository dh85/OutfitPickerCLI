import Foundation

public struct WearOutfitRequest {
    public let outfit: OutfitReference

    public init(outfit: OutfitReference) {
        self.outfit = outfit
    }
}

public struct WearOutfitUseCase: Sendable {
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

    public func execute(request: WearOutfitRequest) async throws {
        try BusinessRules.validateOutfit(request.outfit)

        let config = try configService.load()
        let cache = try cacheService.load()

        let categoryPath = (config.root as NSString).appendingPathComponent(
            request.outfit.category.name)
        let files = try await repository.getOutfits(in: categoryPath)

        guard files.contains(where: { $0.fileName == request.outfit.fileName }) else {
            throw OutfitPickerError.noOutfitsAvailable
        }

        var categoryCache =
            cache.categories[request.outfit.category.name]
            ?? CategoryCache(totalOutfits: files.count)
        guard !categoryCache.wornOutfits.contains(request.outfit.fileName) else { return }

        categoryCache = categoryCache.adding(request.outfit.fileName)
        try cacheService.save(
            cache.updating(category: request.outfit.category.name, with: categoryCache))

        if BusinessRules.shouldResetRotation(
            wornCount: categoryCache.wornOutfits.count, totalCount: files.count)
        {
            let resetCache = CategoryCache(totalOutfits: files.count)
            try cacheService.save(
                cache.updating(category: request.outfit.category.name, with: resetCache))
            throw OutfitPickerError.rotationCompleted(category: request.outfit.category.name)
        }
    }
}
