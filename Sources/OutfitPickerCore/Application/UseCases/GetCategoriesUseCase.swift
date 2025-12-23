import Foundation

public struct GetCategoriesUseCase: Sendable {
    private let repository: CategoryRepositoryProtocol
    private let configService: ConfigServiceProtocol

    public init(repository: CategoryRepositoryProtocol, configService: ConfigServiceProtocol) {
        self.repository = repository
        self.configService = configService
    }

    public func execute() async throws -> [CategoryInfo] {
        let config = try configService.load()
        // Don't filter by excludedCategories here - let all categories appear in menus
        // Exclusion is only applied in random outfit selection methods
        return try await repository.getCategories(
            in: config.root, excludedCategories: [])
    }
}
