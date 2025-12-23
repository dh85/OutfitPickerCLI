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
            try await outfitService.picker.resetCategory(category.name)
            UI.success("Reset worn outfits for \(category.name)")
        } catch {
            UI.error("Failed to reset category: \(error.localizedDescription)")
        }

        await show()
    }

    private func handlePathChange() async {
        do {
            let currentConfig = try await outfitService.picker.getConfiguration()

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

            try await outfitService.picker.updateConfiguration(updatedConfig)
            UI.success("Outfit path updated to: \(newPath)")

        } catch {
            UI.error("Failed to update path: \(error.localizedDescription)")
        }

        await show()
    }

    private func handleLanguageChange() async {
        do {
            let currentConfig = try await outfitService.picker.getConfiguration()

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

            try await outfitService.picker.updateConfiguration(updatedConfig)
            UI.success("Language updated to: \(newLanguage)")

        } catch {
            UI.error("Failed to update language: \(error.localizedDescription)")
        }

        await show()
    }

    private func handleExcludedChange() async {
        do {
            let currentConfig = try await outfitService.picker.getConfiguration()
            let allCategories = try await outfitService.picker.getCategories()

            let excludedList = Array(currentConfig.excludedCategories).sorted()
            let nonExcludedList = allCategories.filter {
                !currentConfig.excludedCategories.contains($0.name)
            }
            .map { $0.name }
            .sorted()

            print("\n🚫 \(UI.colorize("Manage Excluded Categories", UI.bold + UI.cyan))")
            print(UI.colorize(String(repeating: "─", count: 40), UI.cyan))
            print(
                "\nExcluded categories won't appear in random outfit selection across all categories."
            )

            if !excludedList.isEmpty {
                print("\n📋 Currently Excluded:")
                for category in excludedList {
                    print("  • \(UI.colorize(category, UI.red))")
                }
            } else {
                print("\n📋 No categories are currently excluded")
            }

            if !nonExcludedList.isEmpty {
                print("\n✅ Currently Available:")
                for category in nonExcludedList {
                    print("  • \(UI.colorize(category, UI.green))")
                }
            }

            print("\n\(UI.colorize("Options:", UI.bold))")
            if !nonExcludedList.isEmpty {
                print("  \(UI.colorize("[A]", UI.bold + UI.green)) Add category to exclusion list")
            }
            if !excludedList.isEmpty {
                print(
                    "  \(UI.colorize("[R]", UI.bold + UI.green)) Remove category from exclusion list"
                )
                print("  \(UI.colorize("[C]", UI.bold + UI.green)) Clear all exclusions")
            }
            print("  \(UI.colorize("[B]", UI.bold + UI.green)) Back to advanced menu")

            guard let choice = UI.prompt("\nChoose an option: ")?.lowercased() else {
                await show()
                return
            }

            switch choice {
            case "a":
                if nonExcludedList.isEmpty {
                    UI.error("All categories are already excluded")
                    await handleExcludedChange()
                    return
                }

                print("\n➕ \(UI.colorize("Add Categories to Exclusion List", UI.bold))")
                for (index, category) in nonExcludedList.enumerated() {
                    print("  [\(UI.colorize("\(index + 1)", UI.bold + UI.green))] \(category)")
                }

                guard
                    let input = UI.prompt("\nEnter numbers (comma-separated) or category names: "),
                    !input.isEmpty
                else {
                    await handleExcludedChange()
                    return
                }

                var categoriesToAdd: [String] = []

                // Try parsing as numbers first
                let parts = input.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespaces)
                }
                for part in parts {
                    if let index = Int(part), index > 0, index <= nonExcludedList.count {
                        categoriesToAdd.append(nonExcludedList[index - 1])
                    } else if nonExcludedList.contains(part) {
                        categoriesToAdd.append(part)
                    }
                }

                if categoriesToAdd.isEmpty {
                    UI.error("No valid categories selected")
                    await handleExcludedChange()
                    return
                }

                let newExcluded = currentConfig.excludedCategories.union(categoriesToAdd)
                let updatedConfig = try Config(
                    root: currentConfig.root,
                    language: currentConfig.language,
                    excludedCategories: newExcluded
                )

                try await outfitService.picker.updateConfiguration(updatedConfig)
                UI.success("Added to exclusion list: \(categoriesToAdd.joined(separator: ", "))")
                await handleExcludedChange()
                return

            case "r":
                if excludedList.isEmpty {
                    UI.error("No categories are excluded")
                    await handleExcludedChange()
                    return
                }

                print("\n🗑️ \(UI.colorize("Remove Categories from Exclusion List", UI.bold))")
                for (index, category) in excludedList.enumerated() {
                    print("  [\(UI.colorize("\(index + 1)", UI.bold + UI.green))] \(category)")
                }

                guard
                    let input = UI.prompt("\nEnter numbers (comma-separated) or category names: "),
                    !input.isEmpty
                else {
                    await handleExcludedChange()
                    return
                }

                var categoriesToRemove: [String] = []

                // Try parsing as numbers first
                let parts = input.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespaces)
                }
                for part in parts {
                    if let index = Int(part), index > 0, index <= excludedList.count {
                        categoriesToRemove.append(excludedList[index - 1])
                    } else if excludedList.contains(part) {
                        categoriesToRemove.append(part)
                    }
                }

                if categoriesToRemove.isEmpty {
                    UI.error("No valid categories selected")
                    await handleExcludedChange()
                    return
                }

                let newExcluded = currentConfig.excludedCategories.subtracting(categoriesToRemove)
                let updatedConfig = try Config(
                    root: currentConfig.root,
                    language: currentConfig.language,
                    excludedCategories: newExcluded
                )

                try await outfitService.picker.updateConfiguration(updatedConfig)
                UI.success(
                    "Removed from exclusion list: \(categoriesToRemove.joined(separator: ", "))")
                await handleExcludedChange()
                return

            case "c":
                if excludedList.isEmpty {
                    UI.error("No categories are excluded")
                    await handleExcludedChange()
                    return
                }

                let updatedConfig = try Config(
                    root: currentConfig.root,
                    language: currentConfig.language,
                    excludedCategories: []
                )

                try await outfitService.picker.updateConfiguration(updatedConfig)
                UI.success("All exclusions cleared")
                await handleExcludedChange()
                return

            case "b":
                await show()
                return

            default:
                UI.error("Invalid option")
                await handleExcludedChange()
                return
            }

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
            try await outfitService.picker.factoryReset()

            UI.success("All settings and data reset successfully")
            print("🔄 Please restart the application to reconfigure")

        } catch {
            UI.error("Failed to reset settings: \(error.localizedDescription)")
            await show()
        }
    }
}
