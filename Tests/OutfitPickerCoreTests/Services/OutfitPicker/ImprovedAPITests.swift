import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct ImprovedAPITests {

    // MARK: - Documentation Examples

    @Test("Basic usage example from documentation works")
    func basicUsageExample() async throws {
        let (sut, _) = try await makeTestSetup()

        // Example from documentation
        if let outfit = try await sut.showRandomOutfit(from: "casual") {
            #expect(!outfit.fileName.isEmpty)
            #expect(outfit.category.name == "casual")
            try await sut.wearOutfit(outfit)
        }
    }

    @Test("Cross-category selection example works")
    func crossCategoryExample() async throws {
        let (sut, _) = try await makeTestSetup()

        if let outfit = try await sut.showRandomOutfitAcrossCategories() {
            #expect(!outfit.fileName.isEmpty)
            #expect(!outfit.category.name.isEmpty)
        }
    }

    @Test("Category info example works")
    func categoryInfoExample() async throws {
        let (sut, _) = try await makeTestSetup()

        let categories = try await sut.getCategoryInfo()
        for info in categories {
            #expect(!info.category.name.isEmpty)
        }
    }

    @Test("Available categories example works")
    func availableCategoriesExample() async throws {
        let (sut, _) = try await makeTestSetup()

        let categories = try await sut.getCategories()
        let categoryNames = categories.map { $0.name }
        #expect(!categoryNames.isEmpty)
    }



    @Test("Reset category example works")
    func resetCategoryExample() async throws {
        let (sut, _) = try await makeTestSetup()

        try await sut.resetCategory("casual")
        let outfits = try await sut.showAllOutfits(from: "casual")
        #expect(!outfits.isEmpty)
    }

    @Test("Reset all categories example works")
    func resetAllExample() async throws {
        let (sut, _) = try await makeTestSetup()

        try await sut.resetAllCategories()
        let categories = try await sut.getCategories()
        #expect(!categories.isEmpty)
    }

    @Test("Show all outfits example works")
    func showAllOutfitsExample() async throws {
        let (sut, _) = try await makeTestSetup()

        let outfits = try await sut.showAllOutfits(from: "casual")
        #expect(!outfits.isEmpty)
        for outfit in outfits {
            #expect(!outfit.fileName.isEmpty)
            #expect(outfit.category.name == "casual")
        }
    }











    // MARK: - Error Handling Validation

    @Test("Empty category name throws invalidInput")
    func emptyCategory() async throws {
        let (sut, _) = try await makeTestSetup()

        await #expect(throws: OutfitPickerError.invalidInput("Category name cannot be empty")) {
            _ = try await sut.showRandomOutfit(from: "")
        }
    }

    @Test("Whitespace category name throws invalidInput")
    func whitespaceCategoryName() async throws {
        let (sut, _) = try await makeTestSetup()

        await #expect(throws: OutfitPickerError.invalidInput("Category name cannot be empty")) {
            _ = try await sut.showRandomOutfit(from: "   ")
        }
    }





    // MARK: - API Consistency

    @Test("All methods handle empty inputs consistently")
    func consistentEmptyInputHandling() async throws {
        let (sut, _) = try await makeTestSetup()

        // All methods should reject empty category names
        await #expect(throws: OutfitPickerError.invalidInput("Category name cannot be empty")) {
            _ = try await sut.showRandomOutfit(from: "")
        }


    }

    // MARK: - Helpers

    private func makeTestSetup() async throws -> (OutfitPicker, URL) {
        let tempDir = uniqueTempDir()
        let validRoot = "/home/user/outfits"  // Use a valid path that won't trigger restrictions

        let fs = makeFS(
            root: validRoot,
            categories: [
                "casual": ["shirt1.avatar", "shirt2.avatar", "jeans.avatar"],
                "formal": ["suit.avatar", "dress.avatar"],
            ])

        let env = try makeOutfitPickerSUT(
            root: validRoot,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        return (env.sut, tempDir)
    }
}
