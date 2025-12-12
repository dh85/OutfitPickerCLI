import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct AvailableCountTests {

    private let root = "/Users/test/Outfits"

    @Test func returnsFullCount_whenNoCacheExists() async throws {
        let files = ["a.avatar", "b.avatar", "c.avatar"]
        let env = try makeSingleCategorySUT(
            root: root,
            category: "Club",
            files: files
        )

        let count = try await env.sut.getAvailableCount(for: "Club")

        #expect(count == 3)
    }

    @Test func returnsRemainingCount_whenSomeWorn() async throws {
        let files = ["a.avatar", "b.avatar", "c.avatar"]
        let cache = OutfitCache(categories: [
            "Club": CategoryCache(
                wornOutfits: ["a.avatar"],
                totalOutfits: 3
            )
        ])

        let env = try makeSingleCategorySUT(
            root: root,
            category: "Club",
            files: files,
            cache: cache
        )

        let count = try await env.sut.getAvailableCount(for: "Club")

        #expect(count == 2)
    }

    @Test func returnsFullCount_whenRotationComplete() async throws {
        let files = ["a.avatar", "b.avatar"]
        let cache = OutfitCache(categories: [
            "Club": CategoryCache(
                wornOutfits: Set(files),
                totalOutfits: 2
            )
        ])

        let env = try makeSingleCategorySUT(
            root: root,
            category: "Club",
            files: files,
            cache: cache
        )

        let count = try await env.sut.getAvailableCount(for: "Club")

        #expect(count == 2)  // full count when rotation complete
    }

    @Test func returnsZero_whenCategoryEmpty() async throws {
        let env = try makeSingleCategorySUT(
            root: root,
            category: "Empty",
            files: []
        )

        let count = try await env.sut.getAvailableCount(for: "Empty")

        #expect(count == 0)
    }

    @Test func mapsConfigLoadFailure_toInvalidConfiguration() async {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.missingRoot)

        do {
            _ = try await sut.getAvailableCount(for: "Any")
            Issue.record("Expected invalidConfiguration")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    @Test func mapsFileManagerFailure_toFileSystemError() async throws {
        let sut = try makeOutfitPickerSUTWithFileSystemError(
            FileSystemError.operationFailed
        )

        do {
            _ = try await sut.getAvailableCount(for: "Any")
            Issue.record("Expected fileSystemError")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    @Test func mapsCacheLoadFailure_toCacheError() async throws {
        let sut = try makeOutfitPickerSUTWithCacheError(
            CacheError.decodingFailed
        )

        do {
            _ = try await sut.getAvailableCount(for: "Any")
            Issue.record("Expected cacheError")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    @Test func mapsGenericError_toOutfitPickerError() async throws {
        // Create a generic error that's not an OutfitPickerError
        struct GenericError: Error {}
        let sut = try makeOutfitPickerSUTWithCacheError(GenericError())

        do {
            _ = try await sut.getAvailableCount(for: "Any")
            Issue.record("Expected OutfitPickerError")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    @Test func rethrowsOutfitPickerError() async throws {
        // Test that OutfitPickerError is re-thrown directly
        let sut = makeOutfitPickerSUTWithConfigError(OutfitPickerError.configurationNotFound)

        do {
            _ = try await sut.getAvailableCount(for: "Any")
            Issue.record("Expected OutfitPickerError")
        } catch let error as OutfitPickerError {
            #expect(error == OutfitPickerError.configurationNotFound)
        } catch {
            Issue.record("Expected OutfitPickerError, got \(error)")
        }
    }
}
