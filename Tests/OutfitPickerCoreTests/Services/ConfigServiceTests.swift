import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct ConfigServiceTests {

    // MARK: - Round trip

    @Test
    func saveThenLoadRoundTrip() throws {
        try withTempDir { tempDir in
            let sut = makeTestSetup(tempDir: tempDir)
            let original = try sampleConfig()

            try sut.save(original)
            let loaded = try sut.load()

            #expect(loaded == original)
        }
    }

    // MARK: - Delete

    @Test
    func deleteRemovesFile() throws {
        try withTempDir { tempDir in
            let (sut, path) = try makeTestSetupWithSavedConfig(tempDir: tempDir)
            #expect(fileExists(path))

            try sut.delete()
            #expect(!fileExists(path))
        }
    }

    @Test
    func deleteMapsErrorWhenDirectoryProviderFails() {
        let sut = ConfigService(directoryProvider: ThrowingDirectoryProvider())
        #expect(throws: OutfitPickerError.invalidConfiguration) {
            try sut.delete()
        }
    }

    // MARK: - Path & file naming

    @Test
    func configUsesCorrectFileNameAndAppFolder() throws {
        try withTempDir { tempDir in
            let sut = makeTestSetup(tempDir: tempDir)
            let path = try sut.configPath()

            #expect(path.lastPathComponent == "config.json")
            #expect(path.path(percentEncoded: false).contains("outfitpicker"))
        }
    }

    // MARK: - Missing file handling

    @Test
    func loadThrowsWhenConfigFileIsMissing() throws {
        withTempDir { tempDir in
            let sut = makeTestSetup(tempDir: tempDir)

            #expect(throws: OutfitPickerError.configurationNotFound) {
                _ = try sut.load()
            }
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

            try sut.save(try sampleConfig())
            let path = try sut.configPath()
            #expect(fileExists(path))
        }
    }

    // MARK: - Write errors

    @Test
    func writeFailureSurfaces() throws {
        withTempDir { tempDir in
            let sut = ConfigService(
                dataManager: ThrowingDataManager(),
                directoryProvider: FixedDirectoryProvider(url: tempDir)
            )
            #expect(throws: Error.self) {
                try sut.save(try sampleConfig())
            }
        }
    }

    // MARK: - Directory resolution errors

    @Test
    func directoryResolutionErrorMapsToConfigError() {
        let sut = ConfigService(directoryProvider: ThrowingDirectoryProvider())
        #expect(throws: OutfitPickerError.invalidConfiguration) {
            _ = try sut.configPath()
        }
    }

    // MARK: - Helpers

    private func makeTestSetup(tempDir: URL) -> ConfigService {
        ConfigService(
            directoryProvider: FixedDirectoryProvider(url: tempDir)
        )
    }

    private func makeTestSetupWithSavedConfig(tempDir: URL) throws -> (ConfigService, URL) {
        let sut = makeTestSetup(tempDir: tempDir)
        try sut.save(try sampleConfig())
        let path = try sut.configPath()
        return (sut, path)
    }

    private func sampleConfig() throws -> Config {
        try Config(root: "/x", language: "en")
    }

    private func writeCorruptData(to sut: ConfigService) throws {
        let path = try sut.configPath()
        try FileManager.default.createDirectory(
            at: path.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not json".utf8).write(to: path)
    }
}
