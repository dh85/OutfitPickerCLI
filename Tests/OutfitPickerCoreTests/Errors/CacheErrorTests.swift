import Foundation
import Testing

@testable import OutfitPickerCore

struct CacheErrorTests {
    @Test
    func errorDescriptions() {
        testErrorDescriptions([
            (CacheError.encodingFailed, "failed to encode cache data"),
            (CacheError.decodingFailed, "failed to decode cache data"),
            (CacheError.invalidData, "invalid cache data"),
        ])
    }

    @Test
    func equatableSemantics() {
        testEquatableSemantics(
            equal: [(CacheError.encodingFailed, CacheError.encodingFailed)],
            notEqual: [(CacheError.encodingFailed, CacheError.decodingFailed)]
        )
    }
}
