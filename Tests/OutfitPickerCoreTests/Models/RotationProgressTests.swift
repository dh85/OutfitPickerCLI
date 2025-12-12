import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct RotationProgressTests {

    @Test("progress calculation")
    func progressCalculation() {
        let cat = CategoryReference(name: "x", path: "/x")
        let testCases: [(worn: Int, total: Int, expectedProgress: Double)] = [
            (2, 4, 0.5),
            (2, 0, 1.0),
            (2, -1, 1.0),
            (6, 4, 1.5),
        ]

        for (worn, total, expectedProgress) in testCases {
            let progress = RotationProgress(
                category: cat,
                wornCount: worn,
                totalOutfitCount: total,
                isComplete: false
            )
            #expect(progress.progress == expectedProgress)
        }
    }

    @Test("available count behavior")
    func availableCountBehavior() {
        let cat = CategoryReference(name: "x", path: "/x")
        let testCases: [(worn: Int, total: Int, isComplete: Bool, expectedAvailable: Int)] =
            [
                (4, 4, true, 4),
                (3, 4, false, 1),
                (5, 4, false, -1),
            ]

        for (worn, total, isComplete, expectedAvailable) in testCases {
            let progress = RotationProgress(
                category: cat,
                wornCount: worn,
                totalOutfitCount: total,
                isComplete: isComplete
            )
            #expect(progress.availableCount == expectedAvailable)
        }
    }
}
