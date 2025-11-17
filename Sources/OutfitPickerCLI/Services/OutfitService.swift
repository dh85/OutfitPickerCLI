import Foundation
import OutfitPickerCore

struct OutfitService {
    let picker: OutfitPicker

    func getAvailableOutfits(for category: CategoryReference) async throws -> [OutfitReference] {
        let allOutfits = try await picker.showAllOutfits(from: category)
        let availableCount = try await picker.getAvailableCount(for: category)
        
        // If no outfits are available, return empty array
        if availableCount == 0 {
            return []
        }
        
        // If all outfits are available, return all
        if availableCount == allOutfits.count {
            return allOutfits
        }
        
        // Use OutfitPickerCore's showRandomOutfit to determine which outfits are actually available
        // This is more reliable than trying to reconstruct the cache logic
        var availableOutfits: [OutfitReference] = []
        let maxAttempts = allOutfits.count * 2 // Prevent infinite loops
        
        for _ in 0..<maxAttempts {
            if let randomOutfit = try await picker.showRandomOutfit(from: category.name) {
                if !availableOutfits.contains(where: { $0.fileName == randomOutfit.fileName }) {
                    availableOutfits.append(randomOutfit)
                }
                if availableOutfits.count >= availableCount {
                    break
                }
            } else {
                break
            }
        }
        
        return availableOutfits
    }

    func getAllAvailableOutfits() async throws -> [(
        key: String, value: OutfitReference
    )] {
        let categories = try await picker.getCategories()
        var allOutfits: [(key: String, value: OutfitReference)] = []

        for category in categories {
            let availableOutfits = try await getAvailableOutfits(for: category)
            for outfit in availableOutfits {
                let key = "\(category.name)/\(outfit.fileName)"
                allOutfits.append((key: key, value: outfit))
            }
        }
        return allOutfits
    }

    func getActualOutfitCount(for category: CategoryReference) async throws -> Int {
        let url = URL(filePath: category.path, directoryHint: .isDirectory)
        let contents = try FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: nil, options: []
        )

        return contents.filter { fileURL in
            !fileURL.hasDirectoryPath && fileURL.pathExtension.lowercased() == "avatar"
        }.count
    }

    func getWornOutfits() async throws -> [String: [OutfitReference]] {
        let categories = try await picker.getCategories()
        var wornOutfitsByCategory: [String: [OutfitReference]] = [:]

        for category in categories {
            let allOutfits = try await picker.showAllOutfits(from: category)
            let availableOutfits = try await getAvailableOutfits(for: category)
            
            // Worn outfits are those in allOutfits but not in availableOutfits
            let wornOutfits = allOutfits.filter { outfit in
                !availableOutfits.contains { $0.fileName == outfit.fileName }
            }
            
            if !wornOutfits.isEmpty {
                wornOutfitsByCategory[category.name] = wornOutfits.sorted { $0.fileName < $1.fileName }
            }
        }

        return wornOutfitsByCategory
    }

    func getUnwornOutfits() async throws -> [String: [OutfitReference]] {
        let categories = try await picker.getCategories()
        var unwornOutfitsByCategory: [String: [OutfitReference]] = [:]

        for category in categories {
            let availableOutfits = try await getAvailableOutfits(for: category)
            if !availableOutfits.isEmpty {
                unwornOutfitsByCategory[category.name] = availableOutfits.sorted {
                    $0.fileName < $1.fileName
                }
            }
        }

        return unwornOutfitsByCategory
    }
}
