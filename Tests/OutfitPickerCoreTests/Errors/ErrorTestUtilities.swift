import Foundation
import Testing

@testable import OutfitPickerCore

// MARK: - Generic Test Functions

func testErrorDescriptions<E: LocalizedError & Equatable>(
    _ cases: [(error: E, expected: String)]
) {
    for (error, expected) in cases {
        #expect(error.errorDescription == expected)
        #expect(error.errorDescription == error.localizedDescription)
    }
}

func testEquatableSemantics<E: Equatable>(
    equal: [(E, E)],
    notEqual: [(E, E)]
) {
    for (lhs, rhs) in equal {
        #expect(lhs == rhs)
    }
    for (lhs, rhs) in notEqual {
        #expect(lhs != rhs)
    }
}
