import Foundation
import OutfitPickerCore

struct OutfitService {
    let picker: OutfitPicker

    func getAvailableOutfits(for category: CategoryReference) async throws -> [OutfitReference] {
        return try await picker.getAvailableOutfits(from: category)
    }

    func getAllAvailableOutfits() async throws -> [(key: String, value: OutfitReference)] {
        return try await picker.getAllAvailableOutfitsWithKeys().map {
            (key: $0.key, value: $0.outfit)
        }
    }

    func getActualOutfitCount(for category: CategoryReference) async throws -> Int {
        let state = try await picker.getOutfitState(for: category)
        return state.totalCount
    }

    func getWornOutfits2() async throws -> [String: [String]] {
        return try await picker.showAllWornOutfits()
    }

    func getWornOutfits() async throws -> [String: [OutfitReference]] {
        let states = try await picker.getAllOutfitStates()
        return states.compactMapValues { state in
            state.wornOutfits.isEmpty ? nil : state.wornOutfits.sorted { $0.fileName < $1.fileName }
        }
    }

    func getUnwornOutfits() async throws -> [String: [OutfitReference]] {
        let states = try await picker.getAllOutfitStates()
        return states.compactMapValues { state in
            state.availableOutfits.isEmpty
                ? nil : state.availableOutfits.sorted { $0.fileName < $1.fileName }
        }
    }

    func getAvailableCategories() async throws -> [CategoryInfo] {
        let categoryInfos = try await picker.getCategoryInfo()
        return categoryInfos.filter { info in
            if case .hasOutfits = info.state { return true }
            return false
        }
    }
}
