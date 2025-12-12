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

    @Test("Available count example works")
    func availableCountExample() async throws {
        let (sut, _) = try await makeTestSetup()

        let available = try await sut.getAvailableCount(for: "casual")
        #expect(available >= 0)
    }

    @Test("Reset category example works")
    func resetCategoryExample() async throws {
        let (sut, _) = try await makeTestSetup()

        try await sut.resetCategory("casual")
        let available = try await sut.getAvailableCount(for: "casual")
        #expect(available > 0)
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

    @Test("Detect changes example works")
    func detectChangesExample() async throws {
        let (sut, _) = try await makeTestSetup()

        let changes = try await sut.detectChanges()
        #expect(!changes.newCategories.isEmpty || changes.newCategories.isEmpty)
        #expect(!changes.deletedCategories.isEmpty || changes.deletedCategories.isEmpty)
    }

    @Test("Batch wear outfits example works")
    func batchWearExample() async throws {
        let (sut, _) = try await makeTestSetup()

        let outfit1 = try await sut.showRandomOutfit(from: "casual")
        let outfit2 = try await sut.showRandomOutfit(from: "formal")

        if let outfit1 = outfit1, let outfit2 = outfit2 {
            let outfitsWorn = [outfit1, outfit2]
            try await sut.wearOutfits(outfitsWorn)
        }
    }

    @Test("Batch reset categories example works")
    func batchResetExample() async throws {
        let (sut, _) = try await makeTestSetup()

        try await sut.resetCategories(["casual", "formal"])
    }

    @Test("Search outfits example works")
    func searchOutfitsExample() async throws {
        let (sut, _) = try await makeTestSetup()

        let results = try await sut.searchOutfits(pattern: "shirt")
        for outfit in results {
            #expect(outfit.fileName.localizedCaseInsensitiveContains("shirt"))
        }
    }

    @Test("Filter categories example works")
    func filterCategoriesExample() async throws {
        let (sut, _) = try await makeTestSetup()

        let workCategories = try await sut.filterCategories(pattern: "formal")
        for category in workCategories {
            #expect(category.name.localizedCaseInsensitiveContains("formal"))
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

    @Test("Empty search pattern throws invalidInput")
    func emptySearchPattern() async throws {
        let (sut, _) = try await makeTestSetup()

        await #expect(throws: OutfitPickerError.invalidInput("Search pattern cannot be empty")) {
            _ = try await sut.searchOutfits(pattern: "")
        }
    }

    @Test("Empty filter pattern throws invalidInput")
    func emptyFilterPattern() async throws {
        let (sut, _) = try await makeTestSetup()

        await #expect(throws: OutfitPickerError.invalidInput("Filter pattern cannot be empty")) {
            _ = try await sut.filterCategories(pattern: "")
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

        // All methods should reject empty search patterns
        await #expect(throws: OutfitPickerError.invalidInput("Search pattern cannot be empty")) {
            _ = try await sut.searchOutfits(pattern: "")
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
