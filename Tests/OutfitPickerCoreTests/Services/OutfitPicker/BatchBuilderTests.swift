import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct BatchBuilderTests {
    private func makePicker() throws -> OutfitPicker {
        let config = try Config(root: "/test/outfits")
        let configService = FakeConfigService(.ok(config))

        let (_, contents, directories) = makeFS(
            root: "/test/outfits",
            categories: [
                "casual": ["jeans.avatar", "dress.avatar"],
                "formal": ["suit.avatar"],
            ]
        )

        let fileManager = FakeFileManager(.ok(contents), directories: Array(directories))
        let cacheService = FakeCacheService(.ok(OutfitCache()))

        return OutfitPicker(
            configService: configService,
            cacheService: cacheService,
            fileManager: fileManager
        )
    }

    @Test func batchWearOutfits() async throws {
        let picker = try makePicker()
        let outfit1 = try await picker.showRandomOutfit(from: "casual")!
        let outfit2 = try await picker.showRandomOutfit(from: "formal")!

        let result = try await picker.batch()
            .wear(outfit1, outfit2)
            .execute()

        #expect(result.outfitsWorn == 2)
        #expect(result.categoriesReset == 0)
        #expect(result.summary == "2 outfits worn")
    }

    @Test func batchResetCategories() async throws {
        let picker = try makePicker()
        let result = try await picker.batch()
            .reset("casual", "formal")
            .execute()

        #expect(result.outfitsWorn == 0)
        #expect(result.categoriesReset == 2)
        #expect(result.summary == "2 categories reset")
    }

    @Test func batchMixedOperations() async throws {
        let picker = try makePicker()
        let outfit = try await picker.showRandomOutfit(from: "casual")!

        let result = try await picker.batch()
            .wear(outfit)
            .reset("formal")
            .execute()

        #expect(result.outfitsWorn == 1)
        #expect(result.categoriesReset == 1)
        #expect(result.summary == "1 outfits worn, 1 categories reset")
    }

    @Test func batchWearArray() async throws {
        let picker = try makePicker()
        let outfit1 = try await picker.showRandomOutfit(from: "casual")!
        let outfit2 = try await picker.showRandomOutfit(from: "formal")!

        let result = try await picker.batch()
            .wear([outfit1, outfit2])
            .execute()

        #expect(result.outfitsWorn == 2)
    }

    @Test func batchResetArray() async throws {
        let picker = try makePicker()
        let result = try await picker.batch()
            .resetCategories(["casual", "formal"])
            .execute()

        #expect(result.categoriesReset == 2)
    }

    @Test func batchResetCategoryReferences() async throws {
        let picker = try makePicker()
        let categories = try await picker.getCategories()

        let result = try await picker.batch()
            .reset(categories)
            .execute()

        #expect(result.categoriesReset == categories.count)
    }

    @Test func batchEmptyOperations() async throws {
        let picker = try makePicker()
        let result = try await picker.batch().execute()

        #expect(result.outfitsWorn == 0)
        #expect(result.categoriesReset == 0)
        #expect(result.totalOperations == 0)
        #expect(result.summary == "No operations performed")
    }

    @Test func batchChaining() async throws {
        let picker = try makePicker()
        let outfit = try await picker.showRandomOutfit(from: "casual")!

        let result = try await picker.batch()
            .wear(outfit)
            .reset("formal")
            .wear([])  // Empty array should be handled gracefully
            .resetCategories([])  // Empty array should be handled gracefully
            .execute()

        #expect(result.outfitsWorn == 1)
        #expect(result.categoriesReset == 1)
    }
}
