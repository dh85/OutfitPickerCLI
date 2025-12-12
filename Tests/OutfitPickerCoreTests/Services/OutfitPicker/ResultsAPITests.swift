import Foundation
import Testing

@testable import OutfitPickerCore
@testable import OutfitPickerTestSupport

@Test func randomOutfitResultWrapping() async {
    // Given - config service that throws
    let failingConfigService = FakeConfigService(
        .throwsError(OutfitPickerError.configurationNotFound))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(
        configService: failingConfigService,
        cacheService: fakeCacheService,
        fileManager: fakeFileManager
    )

    // When
    let result = await picker.randomOutfit(from: "casual")

    // Then - error is properly wrapped in Result
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.configurationNotFound)
    }
}

@Test func randomOutfitInvalidInput() async {
    // Given
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(
        configService: fakeConfigService,
        cacheService: fakeCacheService,
        fileManager: fakeFileManager
    )

    // When
    let result = await picker.randomOutfit(from: "")

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.invalidInput("Category name cannot be empty"))
    }
}

@Test func wearOutfitResultWrapping() async {
    // Given - config service that throws
    let failingConfigService = FakeConfigService(
        .throwsError(OutfitPickerError.configurationNotFound))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(
        configService: failingConfigService,
        cacheService: fakeCacheService,
        fileManager: fakeFileManager
    )
    let outfit = OutfitReference(
        fileName: "test.avatar", category: CategoryReference(name: "casual", path: "/test/casual"))

    // When
    let result = await picker.wear(outfit)

    // Then - error is properly wrapped in Result
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.configurationNotFound)
    }
}

@Test func wearOutfitInvalidInput() async {
    // Given
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(
        configService: fakeConfigService,
        cacheService: fakeCacheService,
        fileManager: fakeFileManager
    )
    let outfit = OutfitReference(
        fileName: "", category: CategoryReference(name: "casual", path: "/test/casual"))

    // When
    let result = await picker.wear(outfit)

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.invalidInput("Outfit filename cannot be empty"))
    }
}

@Test func availableCategoriesResultWrapping() async {
    // Given - config service that throws
    let failingConfigService = FakeConfigService(
        .throwsError(OutfitPickerError.configurationNotFound))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(
        configService: failingConfigService,
        cacheService: fakeCacheService,
        fileManager: fakeFileManager
    )

    // When
    let result = await picker.availableCategories()

    // Then - error is properly wrapped in Result
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.configurationNotFound)
    }
}

@Test func availableCategoriesEmpty() async {
    // Given - empty filesystem
    let config = try! Config(root: "/test/outfits")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let emptyFileManager = FakeFileManager(
        .ok([URL(filePath: "/test/outfits"): []]), directories: [URL(filePath: "/test/outfits")])
    let picker = OutfitPicker(
        configService: fakeConfigService,
        cacheService: fakeCacheService,
        fileManager: emptyFileManager
    )

    // When
    let result = await picker.availableCategories()

    // Then
    switch result {
    case .success(let categories):
        #expect(categories.isEmpty)
    case .failure:
        Issue.record("Expected success")
    }
}

@Test func resetCategoryResultWrapping() async {
    // Given - config service that throws
    let failingConfigService = FakeConfigService(
        .throwsError(OutfitPickerError.configurationNotFound))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(
        configService: failingConfigService,
        cacheService: fakeCacheService,
        fileManager: fakeFileManager
    )

    // When
    let result = await picker.reset(category: "casual")

    // Then - error is properly wrapped in Result
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.configurationNotFound)
    }
}

@Test func resetCategoryInvalidInput() async {
    // Given
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(
        configService: fakeConfigService,
        cacheService: fakeCacheService,
        fileManager: fakeFileManager
    )

    // When
    let result = await picker.reset(category: "")

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.invalidInput("Category name cannot be empty"))
    }
}

@Test func errorMappingFromGenericError() async {
    // Given - file manager that throws a custom error
    struct CustomError: Error {}
    let config = try! Config(root: "/test/outfits")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let failingFileManager = FakeFileManager(.throwsError(CustomError()))
    let picker = OutfitPicker(
        configService: fakeConfigService,
        cacheService: fakeCacheService,
        fileManager: failingFileManager
    )

    // When
    let result = await picker.randomOutfit(from: "casual")

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        // Should be mapped to OutfitPickerError.fileSystemError (default case)
        #expect(error == OutfitPickerError.fileSystemError)
    }
}

@Test func randomOutfitMethodCall() async {
    // Given
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(
        configService: fakeConfigService,
        cacheService: fakeCacheService,
        fileManager: fakeFileManager
    )

    // When
    let result = await picker.randomOutfit(from: "test")

    // Then - method returns Result type
    switch result {
    case .success(let outfit):
        // Empty category returns nil
        #expect(outfit == nil)
    case .failure:
        Issue.record("Should succeed with nil for empty category")
    }
}

@Test func wearMethodCall() async {
    // Given
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(
        configService: fakeConfigService,
        cacheService: fakeCacheService,
        fileManager: fakeFileManager
    )
    let outfit = OutfitReference(
        fileName: "test.avatar", category: CategoryReference(name: "test", path: "/test"))

    // When
    let result = await picker.wear(outfit)

    // Then - method returns Result type
    switch result {
    case .success:
        Issue.record("Should fail for nonexistent outfit")
    case .failure(let error):
        #expect(error == OutfitPickerError.noOutfitsAvailable)
    }
}

@Test func availableCategoriesMethodCall() async {
    // Given
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(
        .ok([URL(filePath: "/test"): []]), directories: [URL(filePath: "/test")])
    let picker = OutfitPicker(
        configService: fakeConfigService,
        cacheService: fakeCacheService,
        fileManager: fakeFileManager
    )

    // When
    let result = await picker.availableCategories()

    // Then - method returns Result type
    switch result {
    case .success(let categories):
        #expect(categories.isEmpty)
    case .failure:
        Issue.record("Should succeed with empty array")
    }
}

@Test func resetCategoryMethodCall() async {
    // Given
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(
        configService: fakeConfigService,
        cacheService: fakeCacheService,
        fileManager: fakeFileManager
    )

    // When
    let result = await picker.reset(category: "test")

    // Then - method returns Result type
    switch result {
    case .success:
        // Success - reset completed
        break
    case .failure:
        Issue.record("Should succeed for valid category name")
    }
}

@Test func wearOutfitSuccessCase() async throws {
    // Given - setup for successful wear operation using test helpers
    let categoryName = "casual"
    let fileName = "shirt.avatar"
    let safeRoot = "/Users/test/Outfits"

    let env = try makeSingleCategorySUT(
        root: safeRoot,
        category: categoryName,
        files: [fileName, "pants.avatar"]  // 2 outfits so wearing 1 doesn't complete rotation
    )

    let outfit = makeOutfitReference(
        root: safeRoot,
        category: categoryName,
        fileName: fileName
    )

    // When
    let result = await env.sut.wear(outfit)

    // Then - should succeed
    switch result {
    case .success:
        // Success case covered - verify cache was updated
        #expect(env.cache.saved.count == 1)
    case .failure(let error):
        Issue.record("Expected success but got error: \(error)")
    }
}
