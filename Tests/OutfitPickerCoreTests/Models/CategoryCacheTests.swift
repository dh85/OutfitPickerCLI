import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

struct CategoryCacheTests {

    @Test(
        "Rotation completion",
        arguments: [
            (worn: 0, total: 5, complete: false),
            (worn: 3, total: 5, complete: false),
            (worn: 5, total: 5, complete: true),
            (worn: 6, total: 5, complete: true),
            (worn: 0, total: 0, complete: true),
        ]
    )
    func rotationCompletion(worn: Int, total: Int, complete: Bool) {
        let cache = makeCache(worn: worn, total: total)
        #expect(cache.isRotationComplete == complete)
    }

    @Test(
        "Rotation progress",
        arguments: [
            (worn: 0, total: 10, progress: 0.0),
            (worn: 3, total: 10, progress: 0.3),
            (worn: 5, total: 10, progress: 0.5),
            (worn: 10, total: 10, progress: 1.0),
            (worn: 0, total: 0, progress: 1.0),
        ]
    )
    func rotationProgress(worn: Int, total: Int, progress: Double) {
        let cache = makeCache(worn: worn, total: total)
        #expect(abs(cache.rotationProgress - progress) < 0.001)
    }

    @Test(
        "Remaining outfits",
        arguments: [
            (worn: 0, total: 5, remaining: 5),
            (worn: 3, total: 5, remaining: 2),
            (worn: 5, total: 5, remaining: 0),
            (worn: 7, total: 5, remaining: 0),
        ]
    )
    func remainingOutfits(worn: Int, total: Int, remaining: Int) {
        let cache = makeCache(worn: worn, total: total)
        #expect(cache.remainingOutfits == remaining)
    }

    @Test func addingNewFileAddsAndUpdatesTimestamp() {
        let before = Date(timeIntervalSince1970: 1_000)
        let original = CategoryCache(
            wornOutfits: ["a.avatar", "b.avatar"],
            totalOutfits: 5,
            lastUpdated: before
        )

        let updated = original.adding("c.avatar")

        #expect(updated.wornOutfits.count == 3)
        #expect(updated.wornOutfits.contains("c.avatar"))
        #expect(updated.totalOutfits == original.totalOutfits)
        #expect(updated.lastUpdated >= before)
    }

    @Test func addingExistingFileKeepsSetSize() {
        let original = makeCache(worn: 2, total: 5)
        let updated = original.adding("outfit1.avatar")

        #expect(updated.wornOutfits == original.wornOutfits)
        #expect(updated.totalOutfits == original.totalOutfits)
    }

    @Test func resetCacheClearsWornAndKeepsTotals() {
        let original = makeCache(worn: 3, total: 5)
        let reset = original.reset()

        #expect(reset.wornOutfits.isEmpty)
        #expect(reset.totalOutfits == original.totalOutfits)
        #expect(!reset.isRotationComplete)
    }

    @Test func categoryCacheJSONRoundTrip() throws {
        let original = CategoryCache(
            wornOutfits: ["outfit1.avatar", "outfit2.avatar"],
            totalOutfits: 5,
            lastUpdated: Date(timeIntervalSince1970: 1_000_000)
        )

        let decoded: CategoryCache = try roundTrip(original)

        #expect(decoded.wornOutfits == original.wornOutfits)
        #expect(decoded.totalOutfits == original.totalOutfits)
        #expect(
            abs(
                decoded.lastUpdated.timeIntervalSince1970
                    - original.lastUpdated.timeIntervalSince1970
            ) < 1.0
        )
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
