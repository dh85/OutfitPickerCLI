import Foundation
import OutfitPickerCore

struct Configuration {
    let outfitPath: String
    let language: String
    let excludedCategories: [String]

    static func prompt() -> Configuration? {
        guard let path = UI.prompt("Please enter the path to your outfit directory: "),
            !path.isEmpty
        else {
            UI.error("No directory path provided")
            return nil
        }

        let language = UI.prompt("Set language (en is default): ") ?? ""
        let exclude = UI.prompt("Exclude categories (separated by commas, or leave empty): ") ?? ""

        let excludedCategories =
            exclude.isEmpty
            ? []
            : exclude.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

        return Configuration(
            outfitPath: path, language: language, excludedCategories: excludedCategories)
    }

    func createOutfitPicker() async throws -> OutfitPicker {
        return try await OutfitPicker.create { @Sendable builder in
            builder
                .rootDirectory(outfitPath)
                .language(SupportedLanguage(rawValue: language) ?? .english)
                .exclude(categories: Set(excludedCategories))
        }
    }
}
