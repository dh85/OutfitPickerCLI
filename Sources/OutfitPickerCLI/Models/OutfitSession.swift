import Foundation

struct OutfitSession {
    private var globalSkipped: Set<String> = []
    private var categorySkipped: [String: Set<String>] = [:]

    mutating func addSkipped(_ outfitKey: String) {
        globalSkipped.insert(outfitKey)
    }

    mutating func addCategorySkipped(_ fileName: String, category: String) {
        categorySkipped[category, default: []].insert(fileName)
    }

    func isGloballySkipped(_ outfitKey: String) -> Bool {
        globalSkipped.contains(outfitKey)
    }

    func isCategorySkipped(_ fileName: String, category: String) -> Bool {
        categorySkipped[category]?.contains(fileName) ?? false
    }

    mutating func resetGlobal() {
        globalSkipped.removeAll()
    }

    mutating func resetCategory(_ category: String) {
        categorySkipped[category]?.removeAll()
    }

    func globalSkippedCount() -> Int {
        globalSkipped.count
    }

    func categorySkippedCount(_ category: String) -> Int {
        categorySkipped[category]?.count ?? 0
    }
}
