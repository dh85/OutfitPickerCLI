import Foundation
import OutfitPickerCore

struct AdvancedMenu {
    let outfitService: OutfitService

    func show() async {
        UI.header("🔧 Advanced Settings")

        print("📋 \(UI.colorize("Configuration Options", UI.bold + UI.cyan))")
        print("\(UI.colorize(String(repeating: "─", count: 40), UI.cyan))")

        for choice in AdvancedChoice.allCases {
            let keyDisplay =
                "\(UI.colorize("[", UI.cyan))\(UI.colorize(choice.rawValue.uppercased(), UI.bold + UI.green))\(UI.colorize("]", UI.cyan))"
            print("  \(keyDisplay) \(choice.description)")
        }

        guard let input = UI.prompt("\nChoose a letter: ") else { return }

        guard let choice = AdvancedChoice(rawValue: input.lowercased()) else {
            UI.error("Invalid choice")
            await show()
            return
        }

        switch choice {
        case .changePath:
            await handlePathChange()
        case .changeLanguage:
            await handleLanguageChange()
        case .changeExcluded:
            await handleExcludedChange()
        case .resetAll:
            do {
                try await outfitService.picker.resetAllCategories()
                UI.success("All worn outfits reset")
            } catch {
                UI.error("Failed to reset: \(error.localizedDescription)")
            }
            await show()
        case .resetCategory:
            await handleResetCategory()
        case .back:
            await MainMenu(
                outfitService: outfitService,
                presentation: OutfitPresentation(picker: outfitService.picker)
            ).show()
        case .quit:
            print("👋 Goodbye!\n")
            return
        case .resetSettings:
            await handleResetSettings()
        }
    }

    private func handleResetCategory() async {
        do {
            let categories = try await outfitService.picker.getCategories()

            print("\n📁 Select category to reset:")
            for (index, category) in categories.enumerated() {
                print("  [\(UI.colorize("\(index + 1)", UI.bold + UI.green))] \(category.name)")
            }

            guard let input = UI.prompt("\nChoose a number: "),
                let index = Int(input),
                index > 0 && index <= categories.count
            else {
                UI.error("Invalid choice")
                await show()
                return
            }

            let category = categories[index - 1]
            try await outfitService.picker.resetCategory(category)
            UI.success("Reset worn outfits for \(category.name)")
        } catch {
            UI.error("Failed to reset category: \(error.localizedDescription)")
        }

        await show()
    }

    private func handlePathChange() async {
        do {
            let configService = ConfigService()
            let currentConfig = try configService.load()

            print("\n📁 Current outfit path: \(UI.colorize(currentConfig.root, UI.cyan))")

            guard let newPath = UI.prompt("Enter new outfit directory path: "), !newPath.isEmpty
            else {
                UI.error("No path provided")
                await show()
                return
            }

            let updatedConfig = try Config(
                root: newPath,
                language: currentConfig.language,
                excludedCategories: currentConfig.excludedCategories
            )

            try configService.save(updatedConfig)
            UI.success("Outfit path updated to: \(newPath)")

        } catch {
            UI.error("Failed to update path: \(error.localizedDescription)")
        }

        await show()
    }

    private func handleLanguageChange() async {
        do {
            let configService = ConfigService()
            let currentConfig = try configService.load()

            print("\n🌐 Current language: \(UI.colorize(currentConfig.language ?? "en", UI.cyan))")
            print("Available languages: en, es, fr, de, it, pt, ru, ja, ko, zh")

            guard let newLanguage = UI.prompt("Enter new language code: "), !newLanguage.isEmpty
            else {
                UI.error("No language provided")
                await show()
                return
            }

            let updatedConfig = try Config(
                root: currentConfig.root,
                language: newLanguage,
                excludedCategories: currentConfig.excludedCategories
            )

            try configService.save(updatedConfig)
            UI.success("Language updated to: \(newLanguage)")

        } catch {
            UI.error("Failed to update language: \(error.localizedDescription)")
        }

        await show()
    }

    private func handleExcludedChange() async {
        do {
            let configService = ConfigService()
            let currentConfig = try configService.load()
            let categories = try await outfitService.picker.getCategories()

            let currentExcluded = currentConfig.excludedCategories.joined(separator: ", ")
            print(
                "\n🚫 Current excluded categories: \(UI.colorize(currentExcluded.isEmpty ? "none" : currentExcluded, UI.cyan))"
            )

            if !currentConfig.excludedCategories.isEmpty {
                print("\n🗑️ Remove from excluded list:")
                for (index, category) in currentConfig.excludedCategories.enumerated() {
                    print(
                        "  [\(UI.colorize("\(index + 1)", UI.bold + UI.green))] Remove \(UI.colorize(category, UI.red)) from excluded list"
                    )
                }
                print("  [\(UI.colorize("0", UI.bold + UI.red))] Clear all excluded categories")

                if let removeInput = UI.prompt(
                    "\nSelect number to remove (or press Enter to continue): "),
                    !removeInput.isEmpty
                {
                    if let removeIndex = Int(removeInput) {
                        var newExcluded = Array(currentConfig.excludedCategories)
                        if removeIndex == 0 {
                            newExcluded = []
                            UI.success("All exclusions cleared")
                        } else if removeIndex > 0
                            && removeIndex <= currentConfig.excludedCategories.count
                        {
                            let removed = newExcluded.remove(at: removeIndex - 1)
                            UI.success("\(removed) removed from excluded list")
                        } else {
                            UI.error("Invalid selection")
                            await show()
                            return
                        }

                        let updatedConfig = try Config(
                            root: currentConfig.root,
                            language: currentConfig.language,
                            excludedCategories: Set(newExcluded)
                        )
                        try configService.save(updatedConfig)
                        await show()
                        return
                    }
                }
            }

            let availableToExclude = categories.filter {
                !currentConfig.excludedCategories.contains($0.name)
            }

            if !availableToExclude.isEmpty {
                print("\n➕ Add to excluded list:")
                print(
                    "Available categories to exclude: \(availableToExclude.map { $0.name }.joined(separator: ", "))"
                )

                if let addInput = UI.prompt(
                    "Enter categories to add (comma-separated, or press Enter to skip): "),
                    !addInput.isEmpty
                {
                    let categoriesToAdd = addInput.split(separator: ",").map {
                        $0.trimmingCharacters(in: .whitespaces)
                    }
                    let newExcluded = Set(currentConfig.excludedCategories).union(
                        Set(categoriesToAdd))

                    let updatedConfig = try Config(
                        root: currentConfig.root,
                        language: currentConfig.language,
                        excludedCategories: newExcluded
                    )

                    try configService.save(updatedConfig)
                    let displayText =
                        newExcluded.isEmpty ? "none" : newExcluded.joined(separator: ", ")
                    UI.success("Excluded categories updated to: \(displayText)")
                    await show()
                    return
                }
            }

            print("\n🔄 Replace entire excluded list:")
            print("All categories: \(categories.map { $0.name }.joined(separator: ", "))")

            guard
                let input = UI.prompt(
                    "Enter new excluded categories (comma-separated, or empty for none): ")
            else {
                await show()
                return
            }

            let newExcluded =
                input.isEmpty
                ? [] : input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

            let updatedConfig = try Config(
                root: currentConfig.root,
                language: currentConfig.language,
                excludedCategories: Set(newExcluded)
            )

            try configService.save(updatedConfig)
            let displayText = newExcluded.isEmpty ? "none" : newExcluded.joined(separator: ", ")
            UI.success("Excluded categories updated to: \(displayText)")

        } catch {
            UI.error("Failed to update excluded categories: \(error.localizedDescription)")
        }

        await show()
    }

    private func handleResetSettings() async {
        print(
            "⚠️ \(UI.colorize("WARNING:", UI.red)) This will delete all configuration and worn outfit data!"
        )

        guard let confirm = UI.prompt("Are you sure? Type '(y)es' to confirm: "),
            confirm.lowercased() == "yes" || confirm.lowercased() == "y"
        else {
            UI.info("Reset cancelled")
            await show()
            return
        }

        do {
            let configService = ConfigService()
            let cacheService = CacheService()

            try configService.delete()
            try cacheService.delete()

            UI.success("All settings and data reset successfully")
            print("🔄 Please restart the application to reconfigure")

        } catch {
            UI.error("Failed to reset settings: \(error.localizedDescription)")
            await show()
        }
    }
}
