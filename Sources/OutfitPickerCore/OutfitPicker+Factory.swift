import Foundation

extension OutfitPicker {
    /// Creates and configures an OutfitPicker with a single method call.
    ///
    /// This is the simplest way to get started with OutfitPicker. It handles
    /// configuration creation and service setup automatically.
    ///
    /// - Parameter outfitDirectory: Path to your outfit directory
    /// - Returns: Fully configured OutfitPicker ready to use
    /// - Throws: `OutfitPickerError` if setup fails
    ///
    /// ## Example
    /// ```swift
    /// let picker = try await OutfitPicker.create(outfitDirectory: "/Users/me/Outfits")
    /// let outfit = try await picker.showRandomOutfit(from: "casual")
    /// ```
    public static func create(outfitDirectory: String) async throws -> OutfitPicker {
        return try await create(outfitDirectory: outfitDirectory, fileManager: FileManager.default)
    }

    /// Creates an OutfitPicker with custom configuration using ConfigBuilder.
    ///
    /// Use this when you need more control over the configuration, such as
    /// excluding categories or setting language preferences.
    ///
    /// - Parameter builder: Configured ConfigBuilder instance
    /// - Returns: Fully configured OutfitPicker
    /// - Throws: `OutfitPickerError` if setup fails
    ///
    /// ## Example
    /// ```swift
    /// let picker = try await OutfitPicker.create { builder in
    ///     builder.rootDirectory("/Users/me/Outfits")
    ///            .language(.spanish)
    ///            .exclude("damaged", "too-small")
    /// }
    /// ```
    public static func create(
        configuring builder: (ConfigBuilder) -> ConfigBuilder
    ) async throws -> OutfitPicker {
        return try await create(configuring: builder, fileManager: FileManager.default)
    }

    // MARK: - Internal Factory Methods for Testing

    internal static func create(
        outfitDirectory: String,
        fileManager: sending FileManagerProtocol
    ) async throws -> OutfitPicker {
        let config = try Config(root: outfitDirectory)
        let configService = ConfigService(fileManager: fileManager)
        try configService.save(config)
        return OutfitPicker(configService: configService, fileManager: fileManager)
    }

    internal static func create(
        configuring builder: (ConfigBuilder) -> ConfigBuilder,
        fileManager: sending FileManagerProtocol
    ) async throws -> OutfitPicker {
        let config = try builder(ConfigBuilder()).build()
        let configService = ConfigService(fileManager: fileManager)
        try configService.save(config)
        return OutfitPicker(configService: configService, fileManager: fileManager)
    }
}
