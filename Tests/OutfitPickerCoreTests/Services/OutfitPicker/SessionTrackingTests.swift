import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite("Session Tracking Tests")
struct SessionTrackingTests {
    private let root = "/Users/test/Outfits"

    @Test("showNextUniqueRandomOutfit returns different outfits until all shown")
    func showNextUniqueRandomOutfit_returnsDifferentOutfitsUntilAllShown() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "casual": ["outfit1.avatar", "outfit2.avatar", "outfit3.avatar"]
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        var shownOutfits: Set<String> = []

        // Get 3 outfits - should all be unique
        for _ in 1...3 {
            let outfit = try await env.sut.showNextUniqueRandomOutfit()
            #expect(outfit != nil)
            shownOutfits.insert(outfit!.fileName)
        }

        // Should have seen all 3 different outfits
        #expect(shownOutfits.count == 3)
        #expect(shownOutfits == Set(["outfit1.avatar", "outfit2.avatar", "outfit3.avatar"]))

        // 4th call should reset and return one of the outfits again
        let fourthOutfit = try await env.sut.showNextUniqueRandomOutfit()
        #expect(fourthOutfit != nil)
        #expect(shownOutfits.contains(fourthOutfit!.fileName))
    }

    @Test("showNextUniqueRandomOutfit works across multiple categories")
    func showNextUniqueRandomOutfit_worksAcrossMultipleCategories() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "casual": ["casual1.avatar", "casual2.avatar"],
                "formal": ["formal1.avatar", "formal2.avatar"],
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        var shownOutfits: Set<String> = []

        // Get 4 outfits - should all be unique
        for _ in 1...4 {
            let outfit = try await env.sut.showNextUniqueRandomOutfit()
            #expect(outfit != nil)
            let key = "\(outfit!.category.name)/\(outfit!.fileName)"
            #expect(!shownOutfits.contains(key), "Should not repeat: \(key)")
            shownOutfits.insert(key)
        }

        // Should have seen all 4 different outfits
        #expect(shownOutfits.count == 4)
    }

    @Test("showNextUniqueRandomOutfit resets after wearing outfit")
    func showNextUniqueRandomOutfit_resetsAfterWearingOutfit() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "casual": ["outfit1.avatar", "outfit2.avatar"]
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        // Show first outfit
        let firstOutfit = try await env.sut.showNextUniqueRandomOutfit()
        #expect(firstOutfit != nil)

        // Show second outfit
        let secondOutfit = try await env.sut.showNextUniqueRandomOutfit()
        #expect(secondOutfit != nil)
        #expect(firstOutfit!.fileName != secondOutfit!.fileName)

        // Wear the second outfit - this should reset the session
        try await env.sut.wearOutfit(secondOutfit!)

        // Next outfit could be either one (session was reset)
        let thirdOutfit = try await env.sut.showNextUniqueRandomOutfit()
        #expect(thirdOutfit != nil)
    }

    @Test("resetGlobalSession clears tracking")
    func resetGlobalSession_clearsTracking() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "casual": ["outfit1.avatar", "outfit2.avatar", "outfit3.avatar"]
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        var shownFirst: Set<String> = []

        // Show all 3 outfits
        for _ in 1...3 {
            let outfit = try await env.sut.showNextUniqueRandomOutfit()
            #expect(outfit != nil)
            shownFirst.insert(outfit!.fileName)
        }

        // Reset session
        await env.sut.resetGlobalSession()

        var shownAfterReset: Set<String> = []

        // Show all 3 outfits again - should be able to see them all
        for _ in 1...3 {
            let outfit = try await env.sut.showNextUniqueRandomOutfit()
            #expect(outfit != nil)
            shownAfterReset.insert(outfit!.fileName)
        }

        #expect(shownAfterReset.count == 3)
    }

    @Test("showNextUniqueRandomOutfit(from:) tracks per category")
    func showNextUniqueRandomOutfitFromCategory_tracksPerCategory() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "casual": ["casual1.avatar", "casual2.avatar", "casual3.avatar"]
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        var shownOutfits: Set<String> = []

        // Get 3 outfits from casual - should all be unique
        for _ in 1...3 {
            let outfit = try await env.sut.showNextUniqueRandomOutfit(from: "casual")
            #expect(outfit != nil)
            #expect(outfit!.category.name == "casual")
            #expect(!shownOutfits.contains(outfit!.fileName))
            shownOutfits.insert(outfit!.fileName)
        }

        // Should have seen all 3 different outfits
        #expect(shownOutfits.count == 3)

        // 4th call should reset and return one of the outfits again
        let fourthOutfit = try await env.sut.showNextUniqueRandomOutfit(from: "casual")
        #expect(fourthOutfit != nil)
        #expect(shownOutfits.contains(fourthOutfit!.fileName))
    }

    @Test("category session is independent of global session")
    func categorySession_isIndependentOfGlobalSession() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "casual": ["casual1.avatar", "casual2.avatar"],
                "formal": ["formal1.avatar", "formal2.avatar"],
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        // Show outfit from casual using category-specific method
        let casualOutfit1 = try await env.sut.showNextUniqueRandomOutfit(from: "casual")
        #expect(casualOutfit1 != nil)

        // Show outfit globally - could be from any category
        let globalOutfit = try await env.sut.showNextUniqueRandomOutfit()
        #expect(globalOutfit != nil)

        // Show another outfit from casual - should still track independently
        let casualOutfit2 = try await env.sut.showNextUniqueRandomOutfit(from: "casual")
        #expect(casualOutfit2 != nil)
        #expect(casualOutfit1!.fileName != casualOutfit2!.fileName)
    }

    @Test("resetCategorySession clears category tracking")
    func resetCategorySession_clearsCategoryTracking() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "casual": ["outfit1.avatar", "outfit2.avatar"]
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        // Show both outfits
        let first = try await env.sut.showNextUniqueRandomOutfit(from: "casual")
        let second = try await env.sut.showNextUniqueRandomOutfit(from: "casual")
        #expect(first != nil)
        #expect(second != nil)
        #expect(first!.fileName != second!.fileName)

        // Reset category session
        await env.sut.resetCategorySession("casual")

        // Should be able to see both outfits again
        let afterReset1 = try await env.sut.showNextUniqueRandomOutfit(from: "casual")
        let afterReset2 = try await env.sut.showNextUniqueRandomOutfit(from: "casual")
        #expect(afterReset1 != nil)
        #expect(afterReset2 != nil)
        #expect(afterReset1!.fileName != afterReset2!.fileName)
    }

    @Test("showNextUniqueRandomOutfit returns nil when no outfits available")
    func showNextUniqueRandomOutfit_returnsNilWhenNoOutfitsAvailable() async throws {
        let env = try makeOutfitPickerSUT(root: root)

        let outfit = try await env.sut.showNextUniqueRandomOutfit()
        #expect(outfit == nil)
    }

    @Test("showNextUniqueRandomOutfit respects worn outfits")
    func showNextUniqueRandomOutfit_respectsWornOutfits() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "casual": ["outfit1.avatar", "outfit2.avatar", "outfit3.avatar"]
            ]
        )

        let cache = OutfitCache(categories: [
            "casual": CategoryCache(
                wornOutfits: ["outfit1.avatar"],
                totalOutfits: 3
            )
        ])

        let env = try makeOutfitPickerSUT(
            root: root,
            cache: cache,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        var shownOutfits: Set<String> = []

        // Get outfits - should only get the 2 unworn ones
        for _ in 1...2 {
            let outfit = try await env.sut.showNextUniqueRandomOutfit()
            #expect(outfit != nil)
            #expect(outfit!.fileName != "outfit1.avatar", "Should not show worn outfit")
            shownOutfits.insert(outfit!.fileName)
        }

        #expect(shownOutfits.count == 2)
        #expect(shownOutfits == Set(["outfit2.avatar", "outfit3.avatar"]))
    }
}
