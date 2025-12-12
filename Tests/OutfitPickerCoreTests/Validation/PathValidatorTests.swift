import Foundation
import Testing

@testable import OutfitPickerCore

struct PathValidatorTests {
    @Test
    func maximumPathLengthReturns4096() {
        #expect(PathValidator.maximumPathLength == 4096)
    }

    @Test
    func platformRestrictedPathsContainsExpectedPaths() {
        let restrictedPaths = PathValidator.platformRestrictedPaths

        #if os(Windows)
            #expect(restrictedPaths.contains("C:\\Windows\\System32"))
            #expect(restrictedPaths.contains("C:\\Program Files"))
        #else
            #expect(restrictedPaths.contains("/etc"))
            #expect(restrictedPaths.contains("/usr"))
            #expect(restrictedPaths.contains("/bin"))
        #endif
    }
}
