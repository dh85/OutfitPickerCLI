import Foundation

public protocol CategoryScannerProtocol: Sendable {
    func scanCategories(in rootPath: String, excludedCategories: Set<String>) async throws
        -> [CategoryInfo]
    func getOutfits(in categoryPath: String) async throws -> [FileEntry]
}
