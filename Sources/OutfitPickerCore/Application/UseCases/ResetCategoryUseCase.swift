import Foundation

public struct ResetCategoryUseCase: Sendable {
    private let configService: ConfigServiceProtocol
    private let cacheService: CacheServiceProtocol

    public init(configService: ConfigServiceProtocol, cacheService: CacheServiceProtocol) {
        self.configService = configService
        self.cacheService = cacheService
    }

    public func execute(categoryName: String) async throws {
        try BusinessRules.validateCategoryName(categoryName)
        _ = try configService.load()  // Ensure config exists
        let cache = try cacheService.load()
        try cacheService.save(cache.removing(category: categoryName))
    }

    public func executeAll() async throws {
        _ = try configService.load()
        try cacheService.save(OutfitCache())
    }
}
