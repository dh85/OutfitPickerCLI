import Foundation

extension OutfitPicker {
    /// Result-based version of showRandomOutfit for cleaner error handling.
    ///
    /// Returns a Result instead of throwing, making it easier to handle
    /// common cases like "no outfits available" without try/catch blocks.
    ///
    /// - Parameter categoryName: Name of the category to select from
    /// - Returns: Result containing outfit or error
    ///
    /// ## Example
    /// ```swift
    /// let result = await picker.randomOutfit(from: "casual")
    /// switch result {
    /// case .success(let outfit):
    ///     print("Wear: \(outfit.fileName)")
    /// case .failure(.noOutfitsAvailable):
    ///     print("Time to do laundry!")
    /// case .failure(let error):
    ///     print("Error: \(error)")
    /// }
    /// ```
    public func randomOutfit(from categoryName: String) async -> OutfitPickerResult<
        OutfitReference?
    > {
        do {
            let outfit = try await showRandomOutfit(from: categoryName)
            return .success(outfit)
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    /// Result-based version of wearOutfit for cleaner error handling.
    public func wear(_ outfit: OutfitReference) async -> OutfitPickerResult<Void> {
        do {
            try await wearOutfit(outfit)
            return .success(())
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    /// Result-based version of getCategories for cleaner error handling.
    public func availableCategories() async -> OutfitPickerResult<[CategoryReference]> {
        do {
            let categories = try await getCategories()
            return .success(categories)
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    /// Result-based version of resetCategory for cleaner error handling.
    public func reset(category: String) async -> OutfitPickerResult<Void> {
        do {
            try await resetCategory(category)
            return .success(())
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }
}
