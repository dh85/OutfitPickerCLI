import Foundation

/// Core domain service for outfit selection logic
public struct OutfitSelection {

    /// Selects a random outfit from available pool
    public static func selectRandom(from pool: [FileEntry]) -> FileEntry? {
        pool.randomElement()
    }

    /// Selects random category with available outfits
    public static func selectRandomCategory(from categories: [(String, [FileEntry])]) -> (
        String, FileEntry
    )? {
        guard let (categoryName, files) = categories.randomElement(),
            let file = files.randomElement()
        else { return nil }
        return (categoryName, file)
    }
}
