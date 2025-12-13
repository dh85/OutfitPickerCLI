import Foundation
import OutfitPickerCore

public struct FakeCategoryRepository: CategoryRepositoryProtocol {
    private let categoryInfos: [CategoryInfo]
    private let outfitsByPath: [String: [FileEntry]]
    
    public init(categoryInfos: [CategoryInfo] = [], outfitsByPath: [String: [FileEntry]] = [:]) {
        self.categoryInfos = categoryInfos
        self.outfitsByPath = outfitsByPath
    }
    
    public func getCategories(in rootPath: String, excludedCategories: Set<String>) async throws -> [CategoryInfo] {
        return categoryInfos
    }
    
    public func getOutfits(in categoryPath: String) async throws -> [FileEntry] {
        let normalizedPath = categoryPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        if let outfits = outfitsByPath[categoryPath] {
            return outfits.sorted(by: { $0.fileName < $1.fileName })
        }
        
        for (storedPath, outfits) in outfitsByPath {
            let normalizedStoredPath = storedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if normalizedStoredPath == normalizedPath {
                return outfits.sorted(by: { $0.fileName < $1.fileName })
            }
        }
        
        return []
    }

    public func invalidateCache() async {}
}
