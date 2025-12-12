import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct FluentAPITests {
    private func makePicker() throws -> OutfitPicker {
        let config = try Config(root: "/test/outfits")
        let configService = FakeConfigService(.ok(config))

        let (_, contents, directories) = makeFS(
            root: "/test/outfits",
            categories: [
                "casual": ["jeans.avatar", "dress.avatar", "shirt.avatar"]
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

    @Test func fluentSelection() async throws {
        let picker = try makePicker()
        let selection = try await picker.select(from: "casual")
        #expect(selection != nil)
        #expect(selection?.outfit.category.name == "casual")
    }

    @Test func fluentSelectionAndWear() async throws {
        let picker = try makePicker()
        let result = try await picker.select(from: "casual")?.wear()
        #expect(result != nil)
    }

    @Test func fluentAlternatives() async throws {
        let picker = try makePicker()
        let selection = try await picker.select(from: "casual")
        let alternatives = try await selection?.alternatives()

        #expect(alternatives != nil)
        #expect(alternatives?.count == 2)  // 3 total - 1 selected = 2 alternatives
    }

    @Test func fluentIsWorn() async throws {
        let picker = try makePicker()
        let selection = try await picker.select(from: "casual")
        let isWornBefore = try await selection?.isWorn()
        #expect(isWornBefore == false)

        // Test that the wear operation succeeds
        let result = try await selection?.wear()
        #expect(result != nil)
    }

    @Test func fluentWithCategoryReference() async throws {
        let picker = try makePicker()
        let categories = try await picker.getCategories()
        let casualCategory = categories.first { $0.name == "casual" }!

        let selection = try await picker.select(from: casualCategory)
        #expect(selection != nil)
        #expect(selection?.outfit.category.name == "casual")
    }

    @Test func fluentSelectionReturnsNilForEmptyCategory() async throws {
        // Setup picker with empty category
        let config = try Config(root: "/test/outfits")
        let configService = FakeConfigService(.ok(config))

        let (_, contents, directories) = makeFS(
            root: "/test/outfits",
            categories: [
                "casual": ["jeans.avatar", "dress.avatar", "shirt.avatar"],
                "empty": [],
            ]
        )

        let fileManager = FakeFileManager(.ok(contents), directories: Array(directories))
        let cacheService = FakeCacheService(.ok(OutfitCache()))

        let testPicker = OutfitPicker(
            configService: configService,
            cacheService: cacheService,
            fileManager: fileManager
        )

        let selection = try await testPicker.select(from: "empty")
        #expect(selection == nil)
    }
}
