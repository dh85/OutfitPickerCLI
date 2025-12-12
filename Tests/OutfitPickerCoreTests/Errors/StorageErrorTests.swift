import Foundation
import Testing

@testable import OutfitPickerCore

struct StorageErrorTests {
    @Test
    func errorDescriptions() {
        testErrorDescriptions([
            (StorageError.diskFull, "disk full"),
            (StorageError.corruptedData, "data corrupted"),
        ])
    }

    @Test
    func equatableSemantics() {
        testEquatableSemantics(
            equal: [(StorageError.diskFull, StorageError.diskFull)],
            notEqual: [(StorageError.diskFull, StorageError.corruptedData)]
        )
    }
}
