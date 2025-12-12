import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct ConfigBuilderTests {
    private func validateConfig(
        _ config: Config,
        root: String = "/test/path",
        language: String = "en",
        knownCategories: [String] = [],
        excludedCategories: [String] = []
    ) {
        #expect(config.root == root)
        #expect(config.language == language)
        #expect(config.knownCategories == Set(knownCategories))
        #expect(config.excludedCategories == Set(excludedCategories))
    }

    @Test func basicBuild() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.english)
            .build()

        validateConfig(config)
    }

    @Test func missingRoot() {
        #expect(
            throws: OutfitPickerError.invalidInput(
                "Root directory must be set before building config")
        ) {
            try ConfigBuilder().build()
        }
    }

    @Test func missingLanguage() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .build()

        validateConfig(config)
    }

    @Test func categoryOperations() throws {
        let testCases:
            [(
                name: String, builder: (ConfigBuilder) -> ConfigBuilder,
                expectedLanguage: String,
                expectedKnown: [String], expectedExcluded: [String]
            )] = [
                (
                    "excludeCategories",
                    {
                        $0.language(.french).exclude(categories: [
                            "downloads", "documents",
                        ])
                    }, "fr",
                    [], ["downloads", "documents"]
                ),
                (
                    "excludeCategory",
                    { $0.language(.french).exclude(category: "downloads") },
                    "fr", [], ["downloads"]
                ),
                (
                    "includeCategories",
                    {
                        $0.language(.italian).include(categories: [
                            "casual", "formal",
                        ])
                    }, "it",
                    ["casual", "formal"], []
                ),
                (
                    "includeCategory",
                    { $0.language(.portuguese).include(category: "summer") },
                    "pt", ["summer"], []
                ),
            ]

        for testCase in testCases {
            let config = try testCase.builder(
                ConfigBuilder().rootDirectory("/test/path")
            ).build()
            validateConfig(
                config,
                language: testCase.expectedLanguage,
                knownCategories: testCase.expectedKnown,
                excludedCategories: testCase.expectedExcluded
            )
        }
    }

    @Test func knownCategoriesWithStates() throws {
        let categories = [
            "casual": CategoryState.hasOutfits, "formal": CategoryState.empty,
        ]
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.german)
            .knownCategories(categories)
            .build()

        validateConfig(
            config,
            language: "de",
            knownCategories: ["casual", "formal"]
        )
    }

    @Test func chaining() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.spanish)
            .exclude(category: "winter")
            .exclude(categories: ["formal", "party"])
            .include(category: "casual")
            .include(categories: ["summer", "spring"])
            .build()

        validateConfig(
            config,
            language: "es",
            knownCategories: ["casual", "summer", "spring"],
            excludedCategories: ["winter", "formal", "party"]
        )
    }

    @Test func allLanguages() throws {
        for language in SupportedLanguage.allCases {
            let config = try ConfigBuilder()
                .rootDirectory("/test/path")
                .language(language)
                .build()

            validateConfig(config, language: language.rawValue)
        }
    }

    @Test func builderReuse() throws {
        let builder = ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.english)

        let config1 = try builder.exclude(category: "formal").build()
        let config2 = try builder.exclude(category: "casual").build()

        validateConfig(config1, excludedCategories: ["formal"])
        validateConfig(config2, excludedCategories: ["formal", "casual"])
    }

    @Test func variadicAndSequenceOperations() throws {
        let testCases:
            [(
                name: String, builder: (ConfigBuilder) -> ConfigBuilder,
                expectedKnown: [String]
            )] = [
                (
                    "includeVariadic", { $0.include("a", "b", "c") },
                    ["a", "b", "c"]
                ),
                (
                    "knownCategoriesSequence",
                    { $0.knownCategories(["x", "y", "z"].lazy.map { $0 }) },
                    ["x", "y", "z"]
                ),
            ]

        for testCase in testCases {
            let config = try testCase.builder(
                ConfigBuilder().rootDirectory("/test/path")
            ).build()
            validateConfig(config, knownCategories: testCase.expectedKnown)
        }
    }

    @Test func excludeVariadicOperations() throws {
        let testCases:
            [(
                name: String, builder: (ConfigBuilder) -> ConfigBuilder,
                expectedExcluded: [String]
            )] =
                [
                    (
                        "singleAndMultiple",
                        { $0.exclude("downloads", "tmp", "backups") },
                        ["downloads", "tmp", "backups"]
                    ),
                    (
                        "withDuplicatesAndWhitespace",
                        { $0.exclude("tmp", "tmp", " logs ") },
                        ["tmp", "logs"]
                    ),
                    (
                        "worksAlongsideOtherAPIs",
                        {
                            $0.exclude(category: "formal").exclude(categories: [
                                "private"
                            ]).exclude(
                                "archive",
                                "tmp"
                            )
                        }, ["formal", "private", "archive", "tmp"]
                    ),
                ]

        for testCase in testCases {
            let config = try testCase.builder(
                ConfigBuilder().rootDirectory("/test/path")
            ).build()
            validateConfig(
                config,
                excludedCategories: testCase.expectedExcluded
            )
        }
    }

    @Test func builderReuse_withVariadicExclude() throws {
        let builder = ConfigBuilder().rootDirectory("/test/path")

        let c1 = try builder.exclude("a", "b").build()
        let c2 = try builder.exclude("c").build()

        validateConfig(c1, excludedCategories: ["a", "b"])
        validateConfig(c2, excludedCategories: ["a", "b", "c"])
    }
}
