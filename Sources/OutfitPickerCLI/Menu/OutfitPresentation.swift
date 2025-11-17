import Foundation
import OutfitPickerCore

struct OutfitPresentation {
    let picker: OutfitPicker

    func presentOutfitWithCategoryChoice(_ outfit: OutfitReference, category: String) async
        -> OutfitChoice
    {
        return await presentOutfit(outfit, categoryContext: category)
    }

    func presentOutfitWithChoice(_ outfit: OutfitReference) async -> OutfitChoice {
        return await presentOutfit(outfit, categoryContext: nil)
    }
    
    func presentManualOutfit(_ outfit: OutfitReference, category: String, isWorn: Bool) async -> OutfitChoice {
        let cleanName = outfit.fileName.replacingOccurrences(of: ".avatar", with: "")
        let wornText = isWorn ? " \(UI.colorize("(already worn)", UI.yellow))" : ""
        
        print("\n👕 \(UI.colorize("You selected:", UI.bold)) \(UI.colorize(cleanName, UI.bold + UI.cyan)) \(UI.colorize("from \(category)", UI.yellow))\(wornText)")
        
        let prompt = isWorn ? "Wear outfit again? (y)es, (n)o, or (q)uit? " : "Wear this outfit? (y)es, (n)o, or (q)uit? "
        guard let input = UI.prompt(prompt) else {
            return .quit
        }
        
        switch input.lowercased() {
        case "y":
            return await handleWearChoice(outfit)
        case "n":
            return .skipped
        case "q":
            return .quit
        default:
            UI.error("Please enter 'y' for yes, 'n' for no, or 'q' to quit.")
            return await presentManualOutfit(outfit, category: category, isWorn: isWorn)
        }
    }

    private func presentOutfit(_ outfit: OutfitReference, categoryContext: String?) async
        -> OutfitChoice
    {
        showOutfitHeader(outfit, categoryContext: categoryContext)

        guard let input = UI.prompt("Do you want to (w)ear it, (s)kip it, or (q)uit? ") else {
            return .quit
        }

        return await handleUserChoice(input, outfit: outfit, categoryContext: categoryContext)
    }

    private func showOutfitHeader(_ outfit: OutfitReference, categoryContext: String?) {
        let categoryText =
            categoryContext.map { " \(UI.colorize("(from \($0))", UI.yellow))" } ?? ""
        print(
            "\n🎲 \(UI.colorize("I picked this outfit for you:", UI.bold)) \(UI.colorize(outfit.fileName, UI.bold + UI.cyan))\(categoryText)"
        )
    }

    private func handleUserChoice(
        _ input: String, outfit: OutfitReference, categoryContext: String?
    ) async -> OutfitChoice {
        switch input.lowercased() {
        case "w":
            return await handleWearChoice(outfit)
        case "s":
            return handleSkipChoice(outfit, categoryContext: categoryContext)
        case "q":
            return .quit
        default:
            UI.error("Please enter 'w' to wear, 's' to skip, or 'q' to quit.")
            return await presentOutfit(outfit, categoryContext: categoryContext)
        }
    }

    private func handleWearChoice(_ outfit: OutfitReference) async -> OutfitChoice {
        do {
            try await picker.wearOutfit(outfit)
            print()
            UI.success(
                "Perfect! I've saved \(outfit.fileName.replacingOccurrences(of: ".avatar", with: "")) to your worn outfits."
            )
            print()
            return .quit
        } catch OutfitPickerError.rotationCompleted(let category) {
            print()
            UI.success(
                "Perfect! You've now worn all outfits in \(category)! \(outfit.fileName.replacingOccurrences(of: ".avatar", with: "")) was the last one."
            )
            UI.success("🎉 I've reset your \(category) collection so you can wear them all again!")
            print()
            return .quit
        } catch {
            print()
            UI.error("Oops! I couldn't save this outfit. Please try again.")
            print()
            return .quit
        }
    }

    private func handleSkipChoice(_ outfit: OutfitReference, categoryContext: String?)
        -> OutfitChoice
    {
        let categoryText =
            categoryContext.map { " \(UI.colorize("(from \($0))", UI.yellow))" } ?? ""
        print("⚠️ \(UI.colorize("Skipped:", UI.yellow)) \(outfit.fileName)\(categoryText)")
        return .skipped
    }
}
