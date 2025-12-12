import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct SelectionTargetTests {

    @Test("pattern matching")
    func patternMatching() {
        let cat = CategoryReference(name: "casual", path: "/root/casual")
        let targets: [SelectionTarget] = [
            .category(cat),
            .allCategories,
            .categories([cat]),
        ]

        switch targets[0] {
        case .category(let c):
            #expect(c == cat)
        default:
            Issue.record("Expected .category case")
        }

        switch targets[1] {
        case .allCategories:
            #expect(Bool(true))
        default:
            Issue.record("Expected .allCategories case")
        }

        switch targets[2] {
        case .categories(let cs):
            #expect(cs == [cat])
        default:
            Issue.record("Expected .categories case")
        }
    }
}
