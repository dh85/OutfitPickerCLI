import Foundation
import OutfitPickerCore

@main
struct OutfitPickerCLI {
    static func main() async {
        do {
            let picker = try await OutfitPicker.fromExistingConfig()
            let menuSystem = MenuSystem(picker: picker)
            await menuSystem.showMainMenu()
        } catch OutfitPickerError.configurationNotFound {
            UI.info("First time setup")
            guard let config = Configuration.prompt() else { return }
            
            do {
                let picker = try await config.createOutfitPicker()
                let menuSystem = MenuSystem(picker: picker)
                await menuSystem.showMainMenu()
            } catch {
                UI.error("Setup failed: \(error.localizedDescription)")
            }
        } catch {
            UI.error("Error loading config: \(error.localizedDescription)")
        }
    }
}
