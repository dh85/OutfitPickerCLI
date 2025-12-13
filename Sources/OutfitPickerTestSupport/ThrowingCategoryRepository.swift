import Foundation
import OutfitPickerCore

public struct ThrowingCategoryRepository: CategoryRepositoryProtocol {
    private let error: Error
    
    public init(_ error: Error) {
        self.error = error
    }
    
    public func getCategories(in rootPath: String, excludedCategories: Set<String>) async throws -> [CategoryInfo] {
        throw error
    }
    
    public func getOutfits(in categoryPath: String) async throws -> [FileEntry] {
        throw error
    }

    public func invalidateCache() async {}
}
