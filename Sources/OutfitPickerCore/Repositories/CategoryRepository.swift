import Foundation

public protocol CategoryRepositoryProtocol: Sendable {
    func getCategories(in rootPath: String, excludedCategories: Set<String>) async throws
        -> [CategoryInfo]
    func getOutfits(in categoryPath: String) async throws -> [FileEntry]
}

public struct CategoryRepository: CategoryRepositoryProtocol {
    private let categoryScanner: CategoryScannerProtocol

    public init(categoryScanner: CategoryScannerProtocol) {
        self.categoryScanner = categoryScanner
    }

    public func getCategories(in rootPath: String, excludedCategories: Set<String>) async throws
        -> [CategoryInfo]
    {
        return try await categoryScanner.scanCategories(
            in: rootPath, excludedCategories: excludedCategories)
    }

    public func getOutfits(in categoryPath: String) async throws -> [FileEntry] {
        return try await categoryScanner.getOutfits(in: categoryPath)
    }
}
