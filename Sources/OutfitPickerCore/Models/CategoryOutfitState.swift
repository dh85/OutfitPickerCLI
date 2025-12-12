import Foundation

public struct CategoryOutfitState: Sendable {
    public let category: CategoryReference
    public let allOutfits: [OutfitReference]
    public let availableOutfits: [OutfitReference]
    public let wornOutfits: [OutfitReference]

    public var totalCount: Int { allOutfits.count }
    public var availableCount: Int { availableOutfits.count }
    public var wornCount: Int { wornOutfits.count }
    public var progressPercentage: Double {
        BusinessRules.calculateProgress(wornCount: wornCount, totalCount: totalCount)
    }
    public var isRotationComplete: Bool {
        BusinessRules.isRotationComplete(wornCount: wornCount, totalCount: totalCount)
    }
    public var statusText: String {
        BusinessRules.generateStatusText(wornCount: wornCount, totalCount: totalCount)
    }
}
