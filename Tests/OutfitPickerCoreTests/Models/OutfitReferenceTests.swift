import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct OutfitReferenceTests {

    @Test("filePath behavior")
    func filePathBehavior() {
        let testCases: [(fileName: String, categoryPath: String, expectedPath: String)] = [
            ("shirt.avatar", "/test/path", "/test/path/shirt.avatar"),
            ("jeans.avatar", "/test/path/", "/test/path/jeans.avatar"),
        ]

        for (fileName, categoryPath, expectedPath) in testCases {
            let outfit = OutfitReference(
                fileName: fileName,
                category: .init(name: "casual", path: categoryPath)
            )
            #expect(outfit.filePath == expectedPath)
        }
    }

    @Test("description and equatable behavior")
    func descriptionAndEquatable() {
        let category = CategoryReference(name: "casual", path: "/test/path")
        #expect(category.description == "casual")

        let outfit = OutfitReference(
            fileName: "shirt.avatar",
            category: category
        )
        #expect(outfit.description == "shirt.avatar in casual")

        let cat = CategoryReference(name: "casual", path: "/root/casual")
        let a = OutfitReference(fileName: "a.avatar", category: cat)
        let b = OutfitReference(fileName: "a.avatar", category: cat)
        let c = OutfitReference(fileName: "b.avatar", category: cat)

        #expect(a == b)
        #expect(a != c)

        var set = Set<OutfitReference>()
        set.insert(a)
        set.insert(b)
        set.insert(c)
        #expect(set.count == 2)
    }
}
