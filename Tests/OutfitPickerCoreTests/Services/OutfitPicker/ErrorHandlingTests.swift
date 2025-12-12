import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct ErrorHandlingTests {
    private let safeRoot = "/Users/test/Outfits"

    // MARK: - Input Validation Tests

    @Test func showRandomOutfit_WithEmptyCategory_ThrowsInvalidInput() async {
        let env = try! makeOutfitPickerSUT()

        do {
            _ = try await env.sut.showRandomOutfit(from: "")
            Issue.record("Expected invalidInput error")
        } catch OutfitPickerError.invalidInput(let message) {
            #expect(message == "Category name cannot be empty")
        } catch {
            Issue.record("Expected invalidInput error, got \(error)")
        }
    }

    @Test func showRandomOutfit_WithWhitespaceCategory_ThrowsInvalidInput() async {
        let env = try! makeOutfitPickerSUT()

        do {
            _ = try await env.sut.showRandomOutfit(from: "   ")
            Issue.record("Expected invalidInput error")
        } catch OutfitPickerError.invalidInput(let message) {
            #expect(message == "Category name cannot be empty")
        } catch {
            Issue.record("Expected invalidInput error, got \(error)")
        }
    }

    @Test func showRandomOutfit_WithNoOutfits_ReturnsNil() async throws {
        let env = try! makeSingleCategorySUT(category: "Empty", files: [])

        let result = try await env.sut.showRandomOutfit(from: "Empty")
        #expect(result == nil)
    }

    @Test func wearOutfit_WithEmptyFilename_ThrowsInvalidInput() async {
        let env = try! makeOutfitPickerSUT()
        let outfit = makeOutfitReference(root: safeRoot, category: "Test", fileName: "")

        do {
            try await env.sut.wearOutfit(outfit)
            Issue.record("Expected invalidInput error")
        } catch OutfitPickerError.invalidInput(let message) {
            #expect(message == "Outfit filename cannot be empty")
        } catch {
            Issue.record("Expected invalidInput error, got \(error)")
        }
    }

    @Test func wearOutfit_WithEmptyCategory_ThrowsInvalidInput() async {
        let env = try! makeOutfitPickerSUT()
        let outfit = makeOutfitReference(root: safeRoot, category: "", fileName: "test.avatar")

        do {
            try await env.sut.wearOutfit(outfit)
            Issue.record("Expected invalidInput error")
        } catch OutfitPickerError.invalidInput(let message) {
            #expect(message == "Category name cannot be empty")
        } catch {
            Issue.record("Expected invalidInput error, got \(error)")
        }
    }

    @Test func wearOutfit_WithNonExistentOutfit_ThrowsNoOutfitsAvailable() async {
        let env = try! makeSingleCategorySUT(category: "Test", files: ["existing.avatar"])
        let outfit = makeOutfitReference(
            root: safeRoot, category: "Test", fileName: "missing.avatar")

        do {
            try await env.sut.wearOutfit(outfit)
            Issue.record("Expected noOutfitsAvailable error")
        } catch OutfitPickerError.noOutfitsAvailable {
            // Expected
        } catch {
            Issue.record("Expected noOutfitsAvailable error, got \(error)")
        }
    }



    // MARK: - Error Propagation Tests

    @Test func showRandomOutfit_PreservesSpecificErrors() async {
        let configSvc = FakeConfigService(.throwsError(ConfigError.pathTraversalNotAllowed))
        let env = OutfitPickerTestEnv(
            sut: OutfitPicker(
                configService: configSvc, cacheService: FakeCacheService(.ok(OutfitCache())),
                categoryRepository: FakeCategoryRepository()),
            fileManager: FakeFileManager(.ok([:]), directories: []),
            cache: FakeCacheService(.ok(OutfitCache())),
            config: configSvc
        )

        do {
            _ = try await env.sut.showRandomOutfit(from: "Test")
            Issue.record("Expected invalidConfiguration error")
        } catch OutfitPickerError.invalidConfiguration {
            // Expected - ConfigError mapped to invalidConfiguration
        } catch {
            Issue.record("Expected invalidConfiguration error, got \(error)")
        }
    }

    @Test func wearOutfit_PreservesSpecificErrors() async {
        let config = try! Config(root: safeRoot, language: "en")
        let configSvc = FakeConfigService(.ok(config))

        let (dir, map) = makeCategoryDir(root: safeRoot, name: "Test", files: ["test.avatar"])
        let fm = FakeFileManager(.ok(map), directories: [dir])

        let cacheSvc = FakeCacheService(.throwsOnLoad(CacheError.decodingFailed))
        let env = OutfitPickerTestEnv(
            sut: OutfitPicker(configService: configSvc, cacheService: cacheSvc, categoryRepository: FakeCategoryRepository()),
            fileManager: fm,
            cache: cacheSvc,
            config: configSvc
        )
        let outfit = makeOutfitReference(root: safeRoot, category: "Test", fileName: "test.avatar")

        do {
            try await env.sut.wearOutfit(outfit)
            Issue.record("Expected cacheError")
        } catch OutfitPickerError.cacheError {
            // Expected - CacheError mapped to cacheError
        } catch {
            Issue.record("Expected cacheError, got \(error)")
        }
    }



    @Test func isOutfitWorn_MapsGenericError() async {
        let cacheSvc = FakeCacheService(.throwsOnLoad(CacheError.decodingFailed))
        let env = OutfitPickerTestEnv(
            sut: OutfitPicker(
                configService: FakeConfigService(.ok(try! Config(root: safeRoot))),
                cacheService: cacheSvc, categoryRepository: FakeCategoryRepository()),
            fileManager: FakeFileManager(.ok([:]), directories: []),
            cache: cacheSvc,
            config: FakeConfigService(.ok(try! Config(root: safeRoot)))
        )

        do {
            _ = try await env.sut.isOutfitWorn("test.avatar", in: "casual")
            Issue.record("Expected OutfitPickerError")
        } catch OutfitPickerError.cacheError {
            // Expected - CacheError mapped to cacheError
        } catch {
            Issue.record("Expected cacheError, got \(error)")
        }
    }


}
