import Foundation
import OutfitPickerCore

@main
struct OutfitPickerCLI {
    static func main() async {
        let configService = ConfigService()

        do {
            _ = try configService.load()
            let outfitPicker = OutfitPicker()
            let menuSystem = MenuSystem(picker: outfitPicker)
            await menuSystem.showMainMenu()
        } catch OutfitPickerError.configurationNotFound {
            UI.info("First time setup")
            guard let config = Configuration.prompt() else { return }

            do {
                let outfitPicker = try await config.createOutfitPicker()
                let menuSystem = MenuSystem(picker: outfitPicker)
                await menuSystem.showMainMenu()
            } catch {
                UI.error("Setup failed: \(error.localizedDescription)")
            }
        } catch {
            UI.error("Error loading config: \(error.localizedDescription)")
        }
    }
}
