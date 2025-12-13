import Foundation

public protocol CategoryRepositoryProtocol: Sendable {
    func getCategories(in rootPath: String, excludedCategories: Set<String>) async throws
        -> [CategoryInfo]
    func getOutfits(in categoryPath: String) async throws -> [FileEntry]
    func invalidateCache() async
}
