import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct AllOutfitsTests {

    private let root = "/Users/test/Outfits"

    @Test func returnsAllOutfitsFromCategory_sortedByFileName() async throws {
        let files = ["c.avatar", "a.avatar", "b.avatar"]
        let env = try makeSingleCategorySUT(
            root: root,
            category: "Club",
            files: files
        )

        let outfits = try await env.sut.showAllOutfits(from: "Club")

        #expect(outfits.count == 3)
        #expect(outfits.map(\.fileName) == ["a.avatar", "b.avatar", "c.avatar"])
        #expect(outfits.allSatisfy { $0.category.name == "Club" })
        #expect(outfits.allSatisfy { normPath($0.category.path) == "\(root)/Club" })
    }

    @Test func returnsEmptyArray_whenCategoryHasNoAvatarFiles() async throws {
        let env = try makeSingleCategorySUT(
            root: root,
            category: "Empty",
            files: []
        )

        let outfits = try await env.sut.showAllOutfits(from: "Empty")

        #expect(outfits.isEmpty)
    }

    @Test func mapsConfigLoadFailure_toInvalidConfiguration() async {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.missingRoot)

        do {
            _ = try await sut.showAllOutfits(from: "Any")
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
            _ = try await sut.showAllOutfits(from: "Any")
            Issue.record("Expected fileSystemError")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}
