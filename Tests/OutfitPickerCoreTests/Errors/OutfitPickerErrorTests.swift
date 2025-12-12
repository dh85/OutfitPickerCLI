import Foundation
import Testing

@testable import OutfitPickerCore

struct OutfitPickerErrorTests {
    @Test
    func errorDescriptions() {
        testErrorDescriptions([
            (
                OutfitPickerError.configurationNotFound,
                "Configuration not found"
            ),
            (OutfitPickerError.categoryNotFound, "Category not found"),
            (OutfitPickerError.noOutfitsAvailable, "No outfits available"),
            (OutfitPickerError.fileSystemError, "File system error"),
            (OutfitPickerError.cacheError, "Cache error"),
            (OutfitPickerError.invalidConfiguration, "Invalid configuration"),
            (OutfitPickerError.invalidInput("whoops"), "Invalid input: whoops"),
            (
                OutfitPickerError.rotationCompleted(category: "casual"),
                "All outfits in 'casual' have been worn. Category has been reset."
            ),
        ])
    }

    @Test
    func equatableSemantics() {
        testEquatableSemantics(
            equal: [
                (
                    OutfitPickerError.categoryNotFound,
                    OutfitPickerError.categoryNotFound
                ),
                (
                    OutfitPickerError.invalidInput("A"),
                    OutfitPickerError.invalidInput("A")
                ),
                (
                    OutfitPickerError.rotationCompleted(category: "casual"),
                    OutfitPickerError.rotationCompleted(category: "casual")
                ),
            ],
            notEqual: [
                (
                    OutfitPickerError.cacheError,
                    OutfitPickerError.fileSystemError
                ),
                (
                    OutfitPickerError.invalidInput("A"),
                    OutfitPickerError.invalidInput("B")
                ),
                (
                    OutfitPickerError.rotationCompleted(category: "casual"),
                    OutfitPickerError.rotationCompleted(category: "formal")
                ),
            ]
        )
    }

    @Test
    func from_passthroughOutfitPickerError() {
        let original: OutfitPickerError = .noOutfitsAvailable
        #expect(OutfitPickerError.from(original) == original)
    }

    @Test
    func from_mappings() {
        #expect(
            OutfitPickerError.from(ConfigError.pathTraversalNotAllowed)
                == .invalidConfiguration
        )
        #expect(
            OutfitPickerError.from(CacheError.encodingFailed) == .cacheError
        )
        #expect(OutfitPickerError.from(StorageError.diskFull) == .cacheError)
        #expect(
            OutfitPickerError.from(FileSystemError.permissionDenied)
                == .fileSystemError
        )

        struct Unknown: Error {}
        #expect(OutfitPickerError.from(Unknown()) == .fileSystemError)
    }
}
