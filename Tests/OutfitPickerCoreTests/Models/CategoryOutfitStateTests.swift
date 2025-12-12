import Foundation
import Testing

@testable import OutfitPickerCore

@Suite("CategoryOutfitState Tests")
struct CategoryOutfitStateTests {

    @Test("totalCount returns count of all outfits")
    func totalCount() {
        let category = CategoryReference(name: "casual", path: "/test/casual")
        let outfits = [
            OutfitReference(fileName: "outfit1.avatar", category: category),
            OutfitReference(fileName: "outfit2.avatar", category: category),
            OutfitReference(fileName: "outfit3.avatar", category: category),
        ]
        let state = CategoryOutfitState(
            category: category,
            allOutfits: outfits,
            availableOutfits: outfits,
            wornOutfits: []
        )

        #expect(state.totalCount == 3)
    }

    @Test("availableCount returns count of available outfits")
    func availableCount() {
        let category = CategoryReference(name: "casual", path: "/test/casual")
        let available = [
            OutfitReference(fileName: "outfit1.avatar", category: category),
            OutfitReference(fileName: "outfit2.avatar", category: category),
        ]
        let state = CategoryOutfitState(
            category: category,
            allOutfits: available,
            availableOutfits: available,
            wornOutfits: []
        )

        #expect(state.availableCount == 2)
    }

    @Test("wornCount returns count of worn outfits")
    func wornCount() {
        let category = CategoryReference(name: "casual", path: "/test/casual")
        let worn = [
            OutfitReference(fileName: "outfit1.avatar", category: category)
        ]
        let state = CategoryOutfitState(
            category: category,
            allOutfits: worn,
            availableOutfits: [],
            wornOutfits: worn
        )

        #expect(state.wornCount == 1)
    }

    @Test("progressPercentage delegates to BusinessRules")
    func progressPercentage() {
        let category = CategoryReference(name: "casual", path: "/test/casual")
        let all = [
            OutfitReference(fileName: "outfit1.avatar", category: category),
            OutfitReference(fileName: "outfit2.avatar", category: category),
            OutfitReference(fileName: "outfit3.avatar", category: category),
            OutfitReference(fileName: "outfit4.avatar", category: category),
        ]
        let worn = Array(all.prefix(2))
        let available = Array(all.suffix(2))
        let state = CategoryOutfitState(
            category: category,
            allOutfits: all,
            availableOutfits: available,
            wornOutfits: worn
        )

        #expect(state.progressPercentage == 0.5)
    }

    @Test("isRotationComplete delegates to BusinessRules")
    func isRotationComplete() {
        let category = CategoryReference(name: "casual", path: "/test/casual")
        let all = [
            OutfitReference(fileName: "outfit1.avatar", category: category),
            OutfitReference(fileName: "outfit2.avatar", category: category),
        ]
        let state = CategoryOutfitState(
            category: category,
            allOutfits: all,
            availableOutfits: [],
            wornOutfits: all
        )

        #expect(state.isRotationComplete == true)
    }

    @Test("isRotationComplete returns false when not complete")
    func isRotationNotComplete() {
        let category = CategoryReference(name: "casual", path: "/test/casual")
        let all = [
            OutfitReference(fileName: "outfit1.avatar", category: category),
            OutfitReference(fileName: "outfit2.avatar", category: category),
        ]
        let worn = [all[0]]
        let available = [all[1]]
        let state = CategoryOutfitState(
            category: category,
            allOutfits: all,
            availableOutfits: available,
            wornOutfits: worn
        )

        #expect(state.isRotationComplete == false)
    }

    @Test("statusText delegates to BusinessRules")
    func statusText() {
        let category = CategoryReference(name: "casual", path: "/test/casual")
        let all = [
            OutfitReference(fileName: "outfit1.avatar", category: category),
            OutfitReference(fileName: "outfit2.avatar", category: category),
            OutfitReference(fileName: "outfit3.avatar", category: category),
        ]
        let worn = [all[0]]
        let available = Array(all.suffix(2))
        let state = CategoryOutfitState(
            category: category,
            allOutfits: all,
            availableOutfits: available,
            wornOutfits: worn
        )

        #expect(state.statusText == "1 of 3 outfits worn")
    }

    @Test("handles empty state")
    func emptyState() {
        let category = CategoryReference(name: "casual", path: "/test/casual")
        let state = CategoryOutfitState(
            category: category,
            allOutfits: [],
            availableOutfits: [],
            wornOutfits: []
        )

        #expect(state.totalCount == 0)
        #expect(state.availableCount == 0)
        #expect(state.wornCount == 0)
        #expect(state.progressPercentage == 1.0)
        #expect(state.isRotationComplete == true)
        #expect(state.statusText == "0 of 0 outfits worn")
    }
}
