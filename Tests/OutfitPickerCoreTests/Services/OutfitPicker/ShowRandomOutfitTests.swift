import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct ShowRandomOutfitTests {
    private let safeRoot = "/Users/test/Outfits"

    // MARK: - Input Validation

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
            _ = try await env.sut.showRandomOutfit(from: "   \t\n   ")
            Issue.record("Expected invalidInput error")
        } catch OutfitPickerError.invalidInput(let message) {
            #expect(message == "Category name cannot be empty")
        } catch {
            Issue.record("Expected invalidInput error, got \(error)")
        }
    }

    // MARK: - Empty Category Handling

    @Test func showRandomOutfit_WithNoFiles_ReturnsNil() async throws {
        let env = try! makeSingleCategorySUT(category: "Empty", files: [])

        let result = try await env.sut.showRandomOutfit(from: "Empty")
        #expect(result == nil)
    }

    // MARK: - Normal Selection

    @Test func showRandomOutfit_WithAvailableFiles_ReturnsOutfit() async throws {
        let files = ["outfit1.avatar", "outfit2.avatar"]
        let env = try! makeSingleCategorySUT(category: "Test", files: files)

        let result = try await env.sut.showRandomOutfit(from: "Test")

        #expect(result != nil)
        #expect(files.contains(result!.fileName))
        #expect(result!.category.name == "Test")
        #expect(
            result!.category.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                == "\(safeRoot)/Test".trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    @Test func showRandomOutfit_WithNoCache_SelectsFromAllFiles() async throws {
        let files = ["a.avatar", "b.avatar", "c.avatar"]
        let env = try! makeSingleCategorySUT(category: "Fresh", files: files)

        let result = try await env.sut.showRandomOutfit(from: "Fresh")

        #expect(result != nil)
        #expect(files.contains(result!.fileName))
        #expect(env.cache.saved.isEmpty)  // No reset needed
    }

    @Test func showRandomOutfit_WithPartiallyWorn_SelectsFromUnworn() async throws {
        let files = ["worn.avatar", "unworn.avatar"]
        let cache = OutfitCache(categories: [
            "Partial": CategoryCache(wornOutfits: ["worn.avatar"], totalOutfits: 2)
        ])
        let env = try! makeSingleCategorySUT(category: "Partial", files: files, cache: cache)

        let result = try await env.sut.showRandomOutfit(from: "Partial")

        #expect(result?.fileName == "unworn.avatar")
        #expect(env.cache.saved.isEmpty)  // No reset needed
    }

    // MARK: - Rotation Reset

    @Test func showRandomOutfit_WithAllWorn_ResetsAndSelectsFromAll() async throws {
        let files = ["only.avatar"]
        let cache = OutfitCache(categories: [
            "Complete": CategoryCache(wornOutfits: ["only.avatar"], totalOutfits: 1)
        ])
        let env = try! makeSingleCategorySUT(category: "Complete", files: files, cache: cache)

        let result = try await env.sut.showRandomOutfit(from: "Complete")

        #expect(result?.fileName == "only.avatar")
        #expect(env.cache.saved.count == 1)

        let savedCache = try #require(env.cache.saved.first)
        #expect(savedCache.categories["Complete"]?.wornOutfits.isEmpty == true)
        #expect(savedCache.categories["Complete"]?.totalOutfits == 1)
    }

    @Test func showRandomOutfit_WithMultipleAllWorn_ResetsCorrectly() async throws {
        let files = ["first.avatar", "second.avatar"]
        let cache = OutfitCache(categories: [
            "Full": CategoryCache(wornOutfits: Set(files), totalOutfits: 2)
        ])
        let env = try! makeSingleCategorySUT(category: "Full", files: files, cache: cache)

        let result = try await env.sut.showRandomOutfit(from: "Full")

        #expect(result != nil)
        #expect(files.contains(result!.fileName))
        #expect(env.cache.saved.count == 1)

        let savedCache = try #require(env.cache.saved.first)
        #expect(savedCache.categories["Full"]?.wornOutfits.isEmpty == true)
    }

    // MARK: - Path Construction

    @Test func showRandomOutfit_ConstructsCorrectPath() async throws {
        let customRoot = "/custom/root"
        let env = try! makeSingleCategorySUT(
            root: customRoot, category: "PathTest", files: ["test.avatar"])

        let result = try await env.sut.showRandomOutfit(from: "PathTest")

        #expect(
            result?.category.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                == "\(customRoot)/PathTest".trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    // MARK: - Error Handling

    @Test func showRandomOutfit_WithConfigError_ThrowsInvalidConfiguration() async {
        let configSvc = FakeConfigService(.throwsError(ConfigError.pathTraversalNotAllowed))
        let env = OutfitPickerTestEnv(
            sut: OutfitPicker(
                configService: configSvc, cacheService: FakeCacheService(.ok(OutfitCache())),
                fileManager: FakeFileManager(.ok([:]), directories: [])),
            fileManager: FakeFileManager(.ok([:]), directories: []),
            cache: FakeCacheService(.ok(OutfitCache())),
            config: configSvc
        )

        do {
            _ = try await env.sut.showRandomOutfit(from: "Test")
            Issue.record("Expected invalidConfiguration error")
        } catch OutfitPickerError.invalidConfiguration {
            // Expected
        } catch {
            Issue.record("Expected invalidConfiguration error, got \(error)")
        }
    }

    @Test func showRandomOutfit_WithFileSystemError_ThrowsFileSystemError() async {
        let config = try! Config(root: safeRoot, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(.throwsError(FileSystemError.operationFailed), directories: [])
        let env = OutfitPickerTestEnv(
            sut: OutfitPicker(
                configService: configSvc, cacheService: FakeCacheService(.ok(OutfitCache())),
                fileManager: fm),
            fileManager: fm,
            cache: FakeCacheService(.ok(OutfitCache())),
            config: configSvc
        )

        do {
            _ = try await env.sut.showRandomOutfit(from: "Test")
            Issue.record("Expected fileSystemError")
        } catch OutfitPickerError.fileSystemError {
            // Expected
        } catch {
            Issue.record("Expected fileSystemError, got \(error)")
        }
    }

    @Test func showRandomOutfit_WithCacheError_ThrowsCacheError() async {
        let config = try! Config(root: safeRoot, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let (dir, map) = makeCategoryDir(root: safeRoot, name: "Test", files: ["test.avatar"])
        let fm = FakeFileManager(.ok(map), directories: [dir])
        let cacheSvc = FakeCacheService(.throwsOnLoad(CacheError.decodingFailed))
        let env = OutfitPickerTestEnv(
            sut: OutfitPicker(configService: configSvc, cacheService: cacheSvc, fileManager: fm),
            fileManager: fm,
            cache: cacheSvc,
            config: configSvc
        )

        do {
            _ = try await env.sut.showRandomOutfit(from: "Test")
            Issue.record("Expected cacheError")
        } catch OutfitPickerError.cacheError {
            // Expected
        } catch {
            Issue.record("Expected cacheError, got \(error)")
        }
    }
}
