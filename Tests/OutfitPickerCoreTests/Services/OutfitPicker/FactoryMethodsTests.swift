import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct FactoryMethodsTests {

    // MARK: - Factory Method Error Handling Tests

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
    
    @Test func fromExistingConfigSignatureExists() async {
        // Test that fromExistingConfig method signature exists
        // We can't easily run it without a real config file, but we can check it compiles
        let _: () async throws -> OutfitPicker = OutfitPicker.fromExistingConfig
        
        #expect(Bool(true))
    }
}
