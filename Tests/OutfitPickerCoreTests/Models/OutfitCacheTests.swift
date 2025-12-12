import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

struct OutfitCacheTests {

    private func validateCacheUpdate(
        _ updated: OutfitCache,
        _ original: OutfitCache,
        category: String,
        expectedCache: CategoryCache,
        shouldPreserveHeader: Bool = true
    ) {
        #expect(updated.categories[category] == expectedCache)
        if shouldPreserveHeader {
            #expect(updated.version == original.version)
            #expect(updated.createdAt == original.createdAt)
        }
    }

    @Test func updatingOperations() {
        let fixed = Date(timeIntervalSince1970: 2_000_000)
        let testCases:
            [(
                name: String, setup: () -> (OutfitCache, CategoryCache, String),
                validate: (OutfitCache, OutfitCache, CategoryCache, String) ->
                    Void
            )] = [
                (
                    "existingCategory",
                    {
                        let categoryCache = makeCache(
                            worn: 2,
                            total: 5,
                            date: fixed
                        )
                        let original = OutfitCache(
                            categories: ["/casual": categoryCache],
                            version: 7,
                            createdAt: fixed
                        )
                        let newCache = makeCache(worn: 3, total: 5, date: fixed)
                        return (original, newCache, "/casual")
                    },
                    { updated, original, newCache, category in
                        validateCacheUpdate(
                            updated,
                            original,
                            category: category,
                            expectedCache: newCache
                        )
                        #expect(original.categories[category] != newCache)
                    }
                ),
                (
                    "newCategory",
                    {
                        let original = OutfitCache()
                        let newCache = makeCache(worn: 1, total: 3)
                        return (original, newCache, "/formal")
                    },
                    { updated, original, newCache, category in
                        #expect(updated.categories.count == 1)
                        #expect(updated.categories[category] == newCache)
                        #expect(original.categories.isEmpty)
                    }
                ),
            ]

        for testCase in testCases {
            let (original, newCache, category) = testCase.setup()
            let updated = original.updating(category: category, with: newCache)
            testCase.validate(updated, original, newCache, category)
        }
    }

    @Test func resetAllResetsEachCategoryAndPreservesHeader() {
        let fixed = Date(timeIntervalSince1970: 3_000_000)
        let cache1 = makeCache(worn: 3, total: 5, date: fixed)
        let cache2 = makeCache(worn: 2, total: 4, date: fixed)
        let original = OutfitCache(
            categories: ["/casual": cache1, "/formal": cache2],
            version: 2,
            createdAt: fixed
        )

        let reset = original.resetAll()

        let expectedResults = [("/casual", 5), ("/formal", 4)]
        for (category, expectedTotal) in expectedResults {
            #expect(reset.categories[category]?.wornOutfits.isEmpty == true)
            #expect(reset.categories[category]?.totalOutfits == expectedTotal)
        }
        #expect(reset.version == original.version)
        #expect(reset.createdAt == original.createdAt)
        #expect(original.categories["/casual"]?.wornOutfits.count == 3)
    }

    @Test func removingOperations() {
        let testCases:
            [(
                name: String, setup: () -> (OutfitCache, String),
                expectedCount: Int,
                shouldRemain: String?
            )] = [
                (
                    "existingCategory",
                    {
                        let c1 = CategoryCache(
                            wornOutfits: ["shirt.avatar"],
                            totalOutfits: 3
                        )
                        let c2 = CategoryCache(
                            wornOutfits: ["suit.avatar"],
                            totalOutfits: 2
                        )
                        let cache = OutfitCache(categories: [
                            "/casual": c1, "/formal": c2,
                        ])
                        return (cache, "/formal")
                    }, 1, "/casual"
                ),
                (
                    "nonexistentCategory",
                    {
                        let c1 = CategoryCache(
                            wornOutfits: ["shirt.avatar"],
                            totalOutfits: 3
                        )
                        let cache = OutfitCache(categories: ["/casual": c1])
                        return (cache, "/missing")
                    }, 1, "/casual"
                ),
            ]

        for testCase in testCases {
            let (cache, categoryToRemove) = testCase.setup()
            let updated = cache.removing(category: categoryToRemove)

            #expect(updated.categories.count == testCase.expectedCount)
            #expect(updated.categories[categoryToRemove] == nil)
            if let shouldRemain = testCase.shouldRemain {
                #expect(updated.categories[shouldRemain] != nil)
            }
        }
    }

    @Test func resettingOperations() {
        let testCases:
            [(
                name: String, setup: () -> (OutfitCache, String),
                expectedResult: Bool
            )] =
                [
                    (
                        "existingCategory",
                        {
                            let categoryCache = CategoryCache(
                                wornOutfits: ["shirt.avatar", "jeans.avatar"],
                                totalOutfits: 5
                            )
                            let cache = OutfitCache(categories: [
                                "/casual": categoryCache
                            ])
                            return (cache, "/casual")
                        }, true
                    ),
                    (
                        "missingCategory",
                        {
                            let cache = OutfitCache(categories: [:])
                            return (cache, "/invalid")
                        }, false
                    ),
                ]

        for testCase in testCases {
            let (cache, category) = testCase.setup()
            let reset = cache.resetting(category: category)

            if testCase.expectedResult {
                #expect(
                    reset?.categories[category]?.wornOutfits.isEmpty == true
                )
                #expect(reset?.categories[category]?.totalOutfits == 5)
                #expect(cache.categories[category]?.wornOutfits.count == 2)
            } else {
                #expect(reset == nil)
            }
        }
    }

    @Test func jsonRoundTripOperations() throws {
        let testCases: [(name: String, cache: OutfitCache)] = [
            (
                "withCategories",
                {
                    let cat = CategoryCache(
                        wornOutfits: ["test.avatar"],
                        totalOutfits: 3,
                        lastUpdated: Date(timeIntervalSince1970: 2_000_000)
                    )
                    return OutfitCache(
                        categories: ["/casual": cat],
                        version: 2,
                        createdAt: Date(timeIntervalSince1970: 2_000_000)
                    )
                }()
            ),
            ("empty", OutfitCache()),
        ]

        for testCase in testCases {
            let decoded: OutfitCache = try roundTrip(testCase.cache)

            #expect(decoded.categories.count == testCase.cache.categories.count)
            #expect(decoded.version == testCase.cache.version)

            if !testCase.cache.categories.isEmpty {
                #expect(
                    decoded.categories["/casual"]
                        == testCase.cache.categories["/casual"]
                )
                #expect(
                    abs(
                        decoded.createdAt.timeIntervalSince1970
                            - testCase.cache.createdAt.timeIntervalSince1970
                    ) < 1.0
                )
            }
        }
    }

    private func makeCache(worn: Int, total: Int, date: Date = Date())
        -> CategoryCache
    {
        let outfits = Set((0..<worn).map { "outfit\($0).avatar" })
        return CategoryCache(
            wornOutfits: outfits,
            totalOutfits: total,
            lastUpdated: date
        )
    }

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
