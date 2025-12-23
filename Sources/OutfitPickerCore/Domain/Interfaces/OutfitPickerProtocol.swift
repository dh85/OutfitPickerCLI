import Foundation

/// Manages outfit selection and rotation across categories.
public protocol OutfitPickerProtocol: Sendable {
    func showRandomOutfit(from categoryName: String) async throws -> OutfitReference?
    func showRandomOutfitAcrossCategories() async throws -> OutfitReference?
    func showAllWornOutfits() async throws -> [String: [String]]
    func wearOutfit(_ outfit: OutfitReference) async throws
    func getCategoryInfo() async throws -> [CategoryInfo]
    func getCategories() async throws -> [CategoryReference]
    func resetCategory(_ categoryName: String) async throws
    func resetAllCategories() async throws
    func showAllOutfits(from categoryName: String) async throws -> [OutfitReference]
    func isOutfitWorn(_ fileName: String, in categoryName: String) async throws -> Bool
    func getRootDirectory() async throws -> String
    func getConfiguration() async throws -> Config
    func updateConfiguration(_ config: Config) async throws
    func factoryReset() async throws

    // Session-aware outfit selection
    func showNextUniqueRandomOutfit() async throws -> OutfitReference?
    func showNextUniqueRandomOutfit(from categoryName: String) async throws -> OutfitReference?
    func resetGlobalSession() async
    func resetCategorySession(_ categoryName: String) async
}
