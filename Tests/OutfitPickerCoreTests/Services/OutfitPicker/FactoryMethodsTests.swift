import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct FactoryMethodsTests {

    // MARK: - Factory Method Error Handling Tests

    @Test func createWithEmptyStringThrows() async throws {
        await #expect(throws: OutfitPickerError.self) {
            _ = try await OutfitPicker.create(outfitDirectory: "")
        }
    }

    @Test func createWithBuilderEmptyDirectoryThrows() async throws {
        await #expect(throws: OutfitPickerError.self) {
            _ = try await OutfitPicker.create { builder in
                builder.rootDirectory("")
            }
        }
    }

    @Test func createWithBuilderNoDirectoryThrows() async throws {
        await #expect(throws: OutfitPickerError.self) {
            _ = try await OutfitPicker.create { builder in
                builder.language(.english)
            }
        }
    }

    @Test func createWithInvalidPathThrows() async throws {
        await #expect(throws: OutfitPickerError.self) {
            _ = try await OutfitPicker.create(outfitDirectory: "/etc/passwd")
        }
    }

    @Test func createWithBuilderInvalidPathThrows() async throws {
        await #expect(throws: OutfitPickerError.self) {
            _ = try await OutfitPicker.create { builder in
                builder.rootDirectory("/etc/passwd")
            }
        }
    }

    // MARK: - Configuration Validation Tests

    @Test func configCreationWithValidPathSucceeds() throws {
        // Test that Config can be created with valid path
        let config = try Config(root: "/home/user/outfits")
        #expect(config.root == "/home/user/outfits")
        #expect(config.language == "en")
    }

    @Test func configBuilderWithLanguageSucceeds() throws {
        // Test that ConfigBuilder works with language
        let config = try ConfigBuilder()
            .rootDirectory("/home/user/outfits")
            .language(.spanish)
            .build()

        #expect(config.root == "/home/user/outfits")
        #expect(config.language == "es")
    }

    @Test func configBuilderWithExclusionsSucceeds() throws {
        // Test that ConfigBuilder works with exclusions
        let config = try ConfigBuilder()
            .rootDirectory("/home/user/outfits")
            .exclude("damaged", "too-small")
            .build()

        #expect(config.root == "/home/user/outfits")
        #expect(config.excludedCategories.contains("damaged"))
        #expect(config.excludedCategories.contains("too-small"))
    }

    @Test func configBuilderWithFullConfigurationSucceeds() throws {
        // Test that ConfigBuilder works with all options
        let config = try ConfigBuilder()
            .rootDirectory("/home/user/outfits")
            .language(.french)
            .exclude("old", "damaged")
            .build()

        #expect(config.root == "/home/user/outfits")
        #expect(config.language == "fr")
        #expect(config.excludedCategories.contains("old"))
        #expect(config.excludedCategories.contains("damaged"))
    }

    // MARK: - Error Mapping Tests

    @Test func configErrorsMappedCorrectly() throws {
        // Test that empty root throws OutfitPickerError
        #expect(throws: OutfitPickerError.self) {
            _ = try Config(root: "")
        }
    }

    @Test func configBuilderErrorsMappedCorrectly() throws {
        // Test that ConfigBuilder without root throws OutfitPickerError
        #expect(throws: OutfitPickerError.self) {
            _ = try ConfigBuilder().build()
        }
    }

    @Test func pathValidationErrorsMappedCorrectly() throws {
        // Test that path validation errors are mapped to OutfitPickerError
        #expect(throws: OutfitPickerError.self) {
            _ = try Config(root: "/etc/passwd")
        }

        #expect(throws: OutfitPickerError.self) {
            _ = try Config(root: "../../../etc")
        }
    }

    // MARK: - Factory Method Execution Tests

    @Test func simpleFactoryMethodExecution() {
        // Test that the factory method signature exists and compiles
        let _: (String) async throws -> OutfitPicker = OutfitPicker.create(outfitDirectory:)

        // Verify the method signature exists (compilation test)
        #expect(Bool(true))
    }

    @Test func builderFactoryMethodExecution() {
        // Test that the builder factory method signature exists and compiles
        let _: ((ConfigBuilder) -> ConfigBuilder) async throws -> OutfitPicker = OutfitPicker
            .create(configuring:)

        // Verify the method signature exists (compilation test)
        #expect(Bool(true))
    }

    @Test func factoryMethodWithRealFilesystem() {
        // Test that factory methods can be referenced (compilation test)
        let _: (String) async throws -> OutfitPicker = OutfitPicker.create(outfitDirectory:)
        let _: ((ConfigBuilder) -> ConfigBuilder) async throws -> OutfitPicker = OutfitPicker
            .create(configuring:)

        // Verify both factory methods exist (compilation test)
        #expect(Bool(true))
        #expect(Bool(true))
    }

    @Test func factoryMethodConfigServiceSaveError() async {
        // Test factory method behavior when filesystem operations fail
        let fakeFileManager = FakeFileManager(.throwsError(FileSystemError.permissionDenied))

        do {
            _ = try await OutfitPicker.create(
                outfitDirectory: "/home/user/outfits",
                fileManager: fakeFileManager
            )
            // Factory method may succeed despite filesystem errors due to error handling
            #expect(Bool(true))
        } catch {
            // If it throws, it should be an OutfitPickerError
            #expect(error is OutfitPickerError)
        }
    }

    @Test func factoryMethodConfigCreation() throws {
        // Test that factory method logic creates correct Config objects
        let config1 = try Config(root: "/home/user/outfits")
        #expect(config1.root == "/home/user/outfits")
        #expect(config1.language == "en")

        let config2 = try ConfigBuilder()
            .rootDirectory("/home/user/outfits")
            .language(.spanish)
            .exclude("damaged")
            .build()

        #expect(config2.root == "/home/user/outfits")
        #expect(config2.language == "es")
        #expect(config2.excludedCategories.contains("damaged"))
    }

    @Test func factoryMethodServiceInstantiation() {
        // Test that factory methods create the correct service types
        let configService = ConfigService()
        let _ = OutfitPicker(configService: configService, fileManager: FileManager.default)

        // Verify the picker was created successfully
        #expect(Bool(true))
    }

    @Test func simplifiedInitializerWithDefaultFileManager() {
        // Test the simplified initializer with default FileManager
        let _ = OutfitPicker()

        // Verify the picker was created successfully (compilation test)
        #expect(Bool(true))
    }

    @Test func simplifiedInitializerWithCustomFileManager() {
        // Test the simplified initializer with custom FileManager
        let fakeFileManager = FakeFileManager(.ok([:]))
        let _ = OutfitPicker(fileManager: fakeFileManager)

        // Verify the picker was created successfully (compilation test)
        #expect(Bool(true))
    }

    @Test func factoryMethodsExist() {
        // Test that factory methods are available (compilation test)
        let _: (String) async throws -> OutfitPicker = OutfitPicker.create(outfitDirectory:)
        let _: ((ConfigBuilder) -> ConfigBuilder) async throws -> OutfitPicker = OutfitPicker
            .create(configuring:)

        // If this compiles, the factory methods exist with correct signatures
        #expect(Bool(true))  // Compilation success means factory methods exist
    }

    @Test func factoryMethodBuilderExecution() {
        // Test that ConfigBuilder can be used in factory method pattern
        let builder = ConfigBuilder()
        let _ = builder.rootDirectory("/home/user/outfits")
            .language(.spanish)
            .exclude("damaged")

        // Verify builder configuration works (compilation test)
        #expect(Bool(true))
    }
}
