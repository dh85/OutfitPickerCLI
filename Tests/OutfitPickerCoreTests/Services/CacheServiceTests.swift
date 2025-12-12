import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct CacheServiceTests {

    // MARK: - Round trip

    @Test
    func saveThenLoadRoundTrip() throws {
        try withTempDir { tempDir in
            let sut = makeTestSetup(tempDir: tempDir)
            let original = sampleCache()

            try sut.save(original)
            let loaded = try sut.load()

            #expect(loaded == original)
        }
    }

    // MARK: - Delete

    @Test
    func deleteRemovesFile() throws {
        try withTempDir { tempDir in
            let (sut, path) = try makeTestSetupWithSavedCache(tempDir: tempDir)
            #expect(fileExists(path))

            try sut.delete()
            #expect(!fileExists(path))
        }
    }

    @Test
    func deleteMapsErrorWhenDirectoryProviderFails() {
        let sut = CacheService(directoryProvider: ThrowingDirectoryProvider())
        #expect(throws: OutfitPickerError.fileSystemError) {
            try sut.delete()
        }
    }

    // MARK: - Corruption

    @Test
    func loadThrowsOnCorruptJSON() throws {
        try withTempDir { tempDir in
            let sut = makeTestSetup(tempDir: tempDir)
            try writeCorruptData(to: sut)

            #expect(throws: OutfitPickerError.fileSystemError) {
                _ = try sut.load()
            }
        }
    }

    // MARK: - Create-on-save

    @Test
    func saveCreatesMissingDirectories() throws {
        try withTempDir { tempDir in
            let sut = makeTestSetup(tempDir: tempDir)

            try sut.save(OutfitCache())
            let path = try sut.cachePath()
            #expect(fileExists(path))
        }
    }

    // MARK: - Write errors

    @Test
    func writeFailureSurfaces() throws {
        withTempDir { tempDir in
            let sut = CacheService(
                dataManager: ThrowingDataManager(),
                directoryProvider: FixedDirectoryProvider(url: tempDir)
            )
            #expect(throws: Error.self) {
                try sut.save(OutfitCache())
            }
        }
    }

    // MARK: - Directory resolution errors

    @Test
    func directoryResolutionErrorMapsToCacheError() {
        let sut = CacheService(directoryProvider: ThrowingDirectoryProvider())
        #expect(throws: OutfitPickerError.fileSystemError) {
            _ = try sut.cachePath()
        }
    }

    // MARK: - Default on missing file

    @Test
    func loadReturnsDefaultWhenCacheFileIsMissing() throws {
        try withTempDir { tempDir in
            let sut = makeTestSetup(tempDir: tempDir)
            let cache = try sut.load()

            #expect(cache.categories.isEmpty)
            #expect(cache.version == 1)
            #expect(cache.createdAt <= Date())
            #expect(!fileExists(try sut.cachePath()))
        }
    }

    // MARK: - Helpers

    private func makeTestSetup(tempDir: URL) -> CacheService {
        CacheService(
            directoryProvider: FixedDirectoryProvider(url: tempDir)
        )
    }

    private func makeTestSetupWithSavedCache(tempDir: URL) throws -> (CacheService, URL) {
        let sut = makeTestSetup(tempDir: tempDir)
        try sut.save(OutfitCache())
        let path = try sut.cachePath()
        return (sut, path)
    }

    private func sampleCache() -> OutfitCache {
        OutfitCache(categories: [
            "/cat": .init(wornOutfits: ["a"], totalOutfits: 3)
        ])
    }

    private func writeCorruptData(to sut: CacheService) throws {
        let path = try sut.cachePath()
        try FileManager.default.createDirectory(
            at: path.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not json".utf8).write(to: path)
    }
}
