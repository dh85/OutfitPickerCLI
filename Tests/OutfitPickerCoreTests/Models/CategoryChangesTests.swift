import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

struct CategoryChangesTests {

    @Test("hasChanges and isEmpty behavior")
    func hasChangesAndIsEmptyBehavior() {
        let testCases: [(changes: CategoryChanges, hasChanges: Bool, description: String)] =
            [
                (.init(), false, "no changes"),
                (.init(newCategories: ["casual"]), true, "new only"),
                (
                    .init(deletedCategories: ["formal"]), true,
                    "deleted only"
                ),
                (
                    .init(changedCategories: ["summer"]), true,
                    "changed only"
                ),
                (
                    .init(
                        newCategories: ["casual"],
                        deletedCategories: ["formal"],
                        changedCategories: ["summer"]
                    ), true, "mixed changes"
                ),
            ]

        for (changes, expectedHasChanges, _) in testCases {
            #expect(changes.hasChanges == expectedHasChanges)
            #expect(changes.isEmpty == !expectedHasChanges)
        }
    }

    @Test("property integrity")
    func propertyIntegrity() {
        let newSet: Set<String> = ["casual", "formal"]
        let deletedSet: Set<String> = ["beach"]
        let changedSet: Set<String> = ["winter"]

        let changes = CategoryChanges(
            newCategories: newSet,
            deletedCategories: deletedSet,
            changedCategories: changedSet
        )

        #expect(changes.newCategories == newSet)
        #expect(changes.deletedCategories == deletedSet)
        #expect(changes.changedCategories == changedSet)

        var copy = changes
        copy = CategoryChanges(newCategories: ["different"])
        #expect(copy.newCategories != changes.newCategories)
    }
}
