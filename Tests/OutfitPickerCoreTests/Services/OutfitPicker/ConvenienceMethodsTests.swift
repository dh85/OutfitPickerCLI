import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct ConvenienceMethodsTests {

    // MARK: - outfitExists Tests

    @Test("outfitExists returns true for existing outfit")
    func outfitExistsReturnsTrue() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar", "jeans.avatar"]
        )

        let exists = try await env.sut.outfitExists("shirt.avatar", in: "casual")
        #expect(exists == true)
    }

    @Test("outfitExists returns false for non-existing outfit")
    func outfitExistsReturnsFalse() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar", "jeans.avatar"]
        )

        let exists = try await env.sut.outfitExists("nonexistent.avatar", in: "casual")
        #expect(exists == false)
    }

    @Test("outfitExists returns false for non-existing category")
    func outfitExistsReturnsFalseForNonExistingCategory() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let exists = try await env.sut.outfitExists("shirt.avatar", in: "nonexistent")
        #expect(exists == false)
    }

    @Test("outfitExists handles empty category")
    func outfitExistsHandlesEmptyCategory() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "empty",
            files: []
        )

        let exists = try await env.sut.outfitExists("any.avatar", in: "empty")
        #expect(exists == false)
    }

    @Test("outfitExists is case sensitive")
    func outfitExistsIsCaseSensitive() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["Shirt.avatar"]
        )

        let existsExact = try await env.sut.outfitExists("Shirt.avatar", in: "casual")
        let existsLower = try await env.sut.outfitExists("shirt.avatar", in: "casual")

        #expect(existsExact == true)
        #expect(existsLower == false)
    }

    @Test("outfitExists with special characters in filename")
    func outfitExistsWithSpecialCharacters() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt-blue_v2.avatar", "dress (formal).avatar"]
        )

        let exists1 = try await env.sut.outfitExists("shirt-blue_v2.avatar", in: "casual")
        let exists2 = try await env.sut.outfitExists("dress (formal).avatar", in: "casual")

        #expect(exists1 == true)
        #expect(exists2 == true)
    }

    @Test("outfitExists returns false for empty category name")
    func outfitExistsReturnsFalseForEmptyCategoryName() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let exists = try await env.sut.outfitExists("shirt.avatar", in: "")
        #expect(exists == false)
    }

    @Test("outfitExists returns false for whitespace category name")
    func outfitExistsReturnsFalseForWhitespaceCategoryName() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let exists = try await env.sut.outfitExists("shirt.avatar", in: "   ")
        #expect(exists == false)
    }

    @Test("outfitExists handles empty filename")
    func outfitExistsHandlesEmptyFilename() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let exists = try await env.sut.outfitExists("", in: "casual")
        #expect(exists == false)
    }

    @Test("outfitExists with multiple outfits in category")
    func outfitExistsWithMultipleOutfits() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt1.avatar", "shirt2.avatar", "jeans.avatar", "dress.avatar"]
        )

        let exists1 = try await env.sut.outfitExists("shirt1.avatar", in: "casual")
        let exists2 = try await env.sut.outfitExists("jeans.avatar", in: "casual")
        let exists3 = try await env.sut.outfitExists("nonexistent.avatar", in: "casual")

        #expect(exists1 == true)
        #expect(exists2 == true)
        #expect(exists3 == false)
    }

    // MARK: - isOutfitWorn Tests

    @Test("isOutfitWorn returns false for unworn outfit")
    func isOutfitWornReturnsFalseForUnwornOutfit() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let isWorn = try await env.sut.isOutfitWorn("shirt.avatar", in: "casual")
        #expect(isWorn == false)
    }

    @Test("isOutfitWorn returns true for worn outfit")
    func isOutfitWornReturnsTrueForWornOutfit() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 2)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar", "jeans.avatar"],
            cache: cache
        )

        let isWorn = try await env.sut.isOutfitWorn("shirt.avatar", in: "casual")
        #expect(isWorn == true)
    }

    @Test("isOutfitWorn returns false for non-existing category")
    func isOutfitWornReturnsFalseForNonExistingCategory() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let isWorn = try await env.sut.isOutfitWorn("shirt.avatar", in: "nonexistent")
        #expect(isWorn == false)
    }

    @Test("isOutfitWorn returns false for non-existing outfit")
    func isOutfitWornReturnsFalseForNonExistingOutfit() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 1)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"],
            cache: cache
        )

        let isWorn = try await env.sut.isOutfitWorn("nonexistent.avatar", in: "casual")
        #expect(isWorn == false)
    }

    @Test("isOutfitWorn handles empty cache")
    func isOutfitWornHandlesEmptyCache() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"],
            cache: OutfitCache()
        )

        let isWorn = try await env.sut.isOutfitWorn("shirt.avatar", in: "casual")
        #expect(isWorn == false)
    }

    @Test("isOutfitWorn with multiple worn outfits")
    func isOutfitWornWithMultipleWornOutfits() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(
                wornOutfits: ["shirt1.avatar", "jeans.avatar"], totalOutfits: 4)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt1.avatar", "shirt2.avatar", "jeans.avatar", "dress.avatar"],
            cache: cache
        )

        let isWorn1 = try await env.sut.isOutfitWorn("shirt1.avatar", in: "casual")
        let isWorn2 = try await env.sut.isOutfitWorn("jeans.avatar", in: "casual")
        let isWorn3 = try await env.sut.isOutfitWorn("shirt2.avatar", in: "casual")
        let isWorn4 = try await env.sut.isOutfitWorn("dress.avatar", in: "casual")

        #expect(isWorn1 == true)
        #expect(isWorn2 == true)
        #expect(isWorn3 == false)
        #expect(isWorn4 == false)
    }

    @Test("isOutfitWorn is case sensitive")
    func isOutfitWornIsCaseSensitive() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(wornOutfits: ["Shirt.avatar"], totalOutfits: 1)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["Shirt.avatar"],
            cache: cache
        )

        let isWornExact = try await env.sut.isOutfitWorn("Shirt.avatar", in: "casual")
        let isWornLower = try await env.sut.isOutfitWorn("shirt.avatar", in: "casual")

        #expect(isWornExact == true)
        #expect(isWornLower == false)
    }

    @Test("isOutfitWorn handles empty filename")
    func isOutfitWornHandlesEmptyFilename() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 1)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"],
            cache: cache
        )

        let isWorn = try await env.sut.isOutfitWorn("", in: "casual")
        #expect(isWorn == false)
    }

    @Test("isOutfitWorn handles empty category name")
    func isOutfitWornHandlesEmptyCategoryName() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 1)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"],
            cache: cache
        )

        let isWorn = try await env.sut.isOutfitWorn("shirt.avatar", in: "")
        #expect(isWorn == false)
    }

    // MARK: - getOutfit Tests

    @Test("getOutfit returns outfit for existing file")
    func getOutfitReturnsOutfitForExistingFile() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar", "jeans.avatar"]
        )

        let outfit = try await env.sut.getOutfit("shirt.avatar", from: "casual")
        #expect(outfit?.fileName == "shirt.avatar")
        #expect(outfit?.category.name == "casual")
    }

    @Test("getOutfit returns nil for non-existing file")
    func getOutfitReturnsNilForNonExistingFile() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let outfit = try await env.sut.getOutfit("nonexistent.avatar", from: "casual")
        #expect(outfit == nil)
    }

    @Test("getOutfit returns nil for non-existing category")
    func getOutfitReturnsNilForNonExistingCategory() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let outfit = try await env.sut.getOutfit("shirt.avatar", from: "nonexistent")
        #expect(outfit == nil)
    }

    @Test("getOutfit returns nil for empty category")
    func getOutfitReturnsNilForEmptyCategory() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "empty",
            files: []
        )

        let outfit = try await env.sut.getOutfit("any.avatar", from: "empty")
        #expect(outfit == nil)
    }

    @Test("getOutfit is case sensitive")
    func getOutfitIsCaseSensitive() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["Shirt.avatar"]
        )

        let outfitExact = try await env.sut.getOutfit("Shirt.avatar", from: "casual")
        let outfitLower = try await env.sut.getOutfit("shirt.avatar", from: "casual")

        #expect(outfitExact?.fileName == "Shirt.avatar")
        #expect(outfitLower == nil)
    }

    @Test("getOutfit returns first match with multiple files")
    func getOutfitReturnsFirstMatchWithMultipleFiles() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt1.avatar", "shirt2.avatar", "jeans.avatar"]
        )

        let outfit = try await env.sut.getOutfit("shirt2.avatar", from: "casual")
        #expect(outfit?.fileName == "shirt2.avatar")
        #expect(outfit?.category.name == "casual")
    }

    @Test("getOutfit handles empty filename")
    func getOutfitHandlesEmptyFilename() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let outfit = try await env.sut.getOutfit("", from: "casual")
        #expect(outfit == nil)
    }

    @Test("getOutfit returns nil for empty category name")
    func getOutfitReturnsNilForEmptyCategoryName() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let outfit = try await env.sut.getOutfit("shirt.avatar", from: "")
        #expect(outfit == nil)
    }

    @Test("getOutfit with special characters in filename")
    func getOutfitWithSpecialCharactersInFilename() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt-blue_v2.avatar", "dress (formal).avatar"]
        )

        let outfit1 = try await env.sut.getOutfit("shirt-blue_v2.avatar", from: "casual")
        let outfit2 = try await env.sut.getOutfit("dress (formal).avatar", from: "casual")

        #expect(outfit1?.fileName == "shirt-blue_v2.avatar")
        #expect(outfit2?.fileName == "dress (formal).avatar")
    }

    // MARK: - getRotationProgress Tests

    @Test("getRotationProgress returns (0, 3) for no worn outfits")
    func getRotationProgressReturnsZeroForNoWornOutfits() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt1.avatar", "shirt2.avatar", "jeans.avatar"]
        )

        let progress = try await env.sut.getRotationProgress(for: "casual")
        #expect(progress.worn == 0)
        #expect(progress.total == 3)
    }

    @Test("getRotationProgress returns (0, 3) for rotation complete")
    func getRotationProgressReturnsZeroForRotationComplete() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(
                wornOutfits: ["shirt1.avatar", "shirt2.avatar", "jeans.avatar"], totalOutfits: 3)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt1.avatar", "shirt2.avatar", "jeans.avatar"],
            cache: cache
        )

        let progress = try await env.sut.getRotationProgress(for: "casual")
        #expect(progress.worn == 0)  // When rotation complete, available = total, so worn = 0
        #expect(progress.total == 3)
    }

    @Test("getRotationProgress returns (2, 4) for half worn outfits")
    func getRotationProgressReturnsHalfForHalfWornOutfits() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(
                wornOutfits: ["shirt1.avatar", "shirt2.avatar"], totalOutfits: 4)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt1.avatar", "shirt2.avatar", "jeans.avatar", "dress.avatar"],
            cache: cache
        )

        let progress = try await env.sut.getRotationProgress(for: "casual")
        #expect(progress.worn == 2)
        #expect(progress.total == 4)
    }

    @Test("getRotationProgress returns (0, 0) for empty category")
    func getRotationProgressReturnsZeroForEmptyCategory() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "empty",
            files: []
        )

        let progress = try await env.sut.getRotationProgress(for: "empty")
        #expect(progress.worn == 0)
        #expect(progress.total == 0)
    }

    @Test("getRotationProgress calculates correct counts for partial rotation")
    func getRotationProgressCalculatesCorrectCounts() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(wornOutfits: ["shirt1.avatar"], totalOutfits: 3)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt1.avatar", "shirt2.avatar", "jeans.avatar"],
            cache: cache
        )

        let progress = try await env.sut.getRotationProgress(for: "casual")
        #expect(progress.worn == 1)  // 1 worn out of 3 total
        #expect(progress.total == 3)
    }

    @Test("getRotationProgress shows (2, 3) for almost complete rotation")
    func getRotationProgressShowsTwoForAlmostCompleteRotation() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(
                wornOutfits: ["shirt1.avatar", "shirt2.avatar"], totalOutfits: 3)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt1.avatar", "shirt2.avatar", "jeans.avatar"],
            cache: cache
        )

        let progress = try await env.sut.getRotationProgress(for: "casual")
        #expect(progress.worn == 2)  // 2 worn out of 3 total
        #expect(progress.total == 3)
    }

    @Test("getRotationProgress with single outfit unworn")
    func getRotationProgressWithSingleOutfitUnworn() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let progress = try await env.sut.getRotationProgress(for: "casual")
        #expect(progress.worn == 0)
        #expect(progress.total == 1)
    }

    @Test("getRotationProgress with single outfit worn")
    func getRotationProgressWithSingleOutfitWorn() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 1)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"],
            cache: cache
        )

        let progress = try await env.sut.getRotationProgress(for: "casual")
        #expect(progress.worn == 0)  // When rotation complete, available = total, so worn = 0
        #expect(progress.total == 1)
    }

    @Test("getRotationProgress returns (0, 0) for non-existing category")
    func getRotationProgressReturnsZeroForNonExistingCategory() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        let progress = try await env.sut.getRotationProgress(for: "nonexistent")
        #expect(progress.worn == 0)  // Empty category returns (0, 0)
        #expect(progress.total == 0)
    }

    @Test("getRotationProgress throws for empty category name")
    func getRotationProgressThrowsForEmptyCategoryName() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt.avatar"]
        )

        await #expect(throws: OutfitPickerError.invalidInput("Category name cannot be empty")) {
            _ = try await env.sut.getRotationProgress(for: "")
        }
    }

    // MARK: - getRotationProgressPercentage Tests

    @Test("getRotationProgressPercentage returns 0.5 for half worn outfits")
    func getRotationProgressPercentageReturnsHalfForHalfWornOutfits() async throws {
        let cache = OutfitCache(categories: [
            "casual": CategoryCache(
                wornOutfits: ["shirt1.avatar", "shirt2.avatar"], totalOutfits: 4)
        ])
        let env = try makeOutfitPickerSUTWithCategory(
            category: "casual",
            files: ["shirt1.avatar", "shirt2.avatar", "jeans.avatar", "dress.avatar"],
            cache: cache
        )

        let percentage = try await env.sut.getRotationProgressPercentage(for: "casual")
        #expect(percentage == 0.5)
    }

    @Test("getRotationProgressPercentage returns 1.0 for empty category")
    func getRotationProgressPercentageReturnsOneForEmptyCategory() async throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "empty",
            files: []
        )

        let percentage = try await env.sut.getRotationProgressPercentage(for: "empty")
        #expect(percentage == 1.0)
    }
}
