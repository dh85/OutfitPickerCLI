import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct CategoryReferenceExtensionTests {

    @Test
    func showRandomOutfit_WithCategoryReference_CallsStringVersion() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar", "jeans.avatar"]
        )

        let categoryRef = CategoryReference(name: "casual", path: "/test/casual")
        let outfit = try await env.sut.showRandomOutfit(from: categoryRef)

        #expect(outfit != nil)
        #expect(outfit?.category.name == "casual")
    }

    @Test
    func getAvailableCount_WithCategoryReference_CallsStringVersion() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar", "jeans.avatar"]
        )

        let categoryRef = CategoryReference(name: "casual", path: "/test/casual")
        let count = try await env.sut.getAvailableCount(for: categoryRef)

        #expect(count == 2)
    }

    @Test
    func resetCategory_WithCategoryReference_CallsStringVersion() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let categoryRef = CategoryReference(name: "casual", path: "/test/casual")
        try await env.sut.resetCategory(categoryRef)

        // Verify reset worked by checking cache was saved
        #expect(env.cache.saved.count == 1)
    }

    @Test
    func partialReset_WithCategoryReference_CallsStringVersion() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt1.avatar", "shirt2.avatar", "shirt3.avatar"]
        )

        let categoryRef = CategoryReference(name: "casual", path: "/test/casual")
        try await env.sut.partialReset(category: categoryRef, wornCount: 1)

        // Verify partial reset worked by checking cache was saved
        #expect(env.cache.saved.count == 1)
    }

    @Test
    func showAllOutfits_WithCategoryReference_CallsStringVersion() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar", "jeans.avatar"]
        )

        let categoryRef = CategoryReference(name: "casual", path: "/test/casual")
        let outfits = try await env.sut.showAllOutfits(from: categoryRef)

        #expect(outfits.count == 2)
        #expect(outfits.map(\.fileName).sorted() == ["jeans.avatar", "shirt.avatar"])
    }

    @Test
    func getRotationProgress_WithCategoryReference_CallsStringVersion() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar", "jeans.avatar"]
        )

        let categoryRef = CategoryReference(name: "casual", path: "/test/casual")
        let progress = try await env.sut.getRotationProgress(for: categoryRef)

        #expect(progress.worn == 0)
        #expect(progress.total == 2)
    }
}
