import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct FilteringSearchTests {
    private let safeRoot = "/Users/test/Outfits"

    // MARK: - searchOutfits Tests

    @Test func searchOutfits_WithEmptyPattern_ThrowsInvalidInput() async {
        let env = try! makeOutfitPickerSUT()

        do {
            _ = try await env.sut.searchOutfits(pattern: "")
            Issue.record("Expected invalidInput error")
        } catch OutfitPickerError.invalidInput(let message) {
            #expect(message == "Search pattern cannot be empty")
        } catch {
            Issue.record("Expected invalidInput error, got \(error)")
        }
    }

    @Test func searchOutfits_WithWhitespacePattern_ThrowsInvalidInput() async {
        let env = try! makeOutfitPickerSUT()

        do {
            _ = try await env.sut.searchOutfits(pattern: "   \t\n   ")
            Issue.record("Expected invalidInput error")
        } catch OutfitPickerError.invalidInput(let message) {
            #expect(message == "Search pattern cannot be empty")
        } catch {
            Issue.record("Expected invalidInput error, got \(error)")
        }
    }

    @Test func searchOutfits_WithMatchingFiles_ReturnsMatches() async throws {
        let fs = makeFS(
            root: safeRoot,
            categories: [
                "Casual": ["summer_dress.avatar", "winter_coat.avatar", "spring_jacket.avatar"],
                "Formal": ["evening_dress.avatar", "business_suit.avatar"],
            ])
        let env = try! makeOutfitPickerSUT(
            fileSystem: fs.contents, directories: Array(fs.directories))

        let results = try await env.sut.searchOutfits(pattern: "dress")

        #expect(results.count == 2)
        #expect(
            results.contains {
                $0.fileName == "summer_dress.avatar" && $0.category.name == "Casual"
            })
        #expect(
            results.contains {
                $0.fileName == "evening_dress.avatar" && $0.category.name == "Formal"
            })
    }

    @Test func searchOutfits_CaseInsensitive_ReturnsMatches() async throws {
        let fs = makeFS(
            root: safeRoot,
            categories: [
                "Test": ["UPPER.avatar", "lower.avatar", "MiXeD.avatar"]
            ])
        let env = try! makeOutfitPickerSUT(
            fileSystem: fs.contents, directories: Array(fs.directories))

        let results = try await env.sut.searchOutfits(pattern: "upper")

        #expect(results.count == 1)
        #expect(results[0].fileName == "UPPER.avatar")
    }

    @Test func searchOutfits_WithNoMatches_ReturnsEmpty() async throws {
        let fs = makeFS(
            root: safeRoot,
            categories: [
                "Test": ["file1.avatar", "file2.avatar"]
            ])
        let env = try! makeOutfitPickerSUT(
            fileSystem: fs.contents, directories: Array(fs.directories))

        let results = try await env.sut.searchOutfits(pattern: "nonexistent")

        #expect(results.isEmpty)
    }

    @Test func searchOutfits_ResultsSortedByFileName() async throws {
        let fs = makeFS(
            root: safeRoot,
            categories: [
                "Test": ["zebra_outfit.avatar", "alpha_outfit.avatar", "beta_outfit.avatar"]
            ])
        let env = try! makeOutfitPickerSUT(
            fileSystem: fs.contents, directories: Array(fs.directories))

        let results = try await env.sut.searchOutfits(pattern: "outfit")

        #expect(results.count == 3)
        #expect(results[0].fileName == "alpha_outfit.avatar")
        #expect(results[1].fileName == "beta_outfit.avatar")
        #expect(results[2].fileName == "zebra_outfit.avatar")
    }

    @Test func searchOutfits_SkipsExcludedCategories() async throws {
        let config = try Config(
            root: safeRoot,
            language: "en",
            excludedCategories: ["Excluded"],
            knownCategories: [],
            knownCategoryFiles: [:]
        )
        let fs = makeFS(
            root: safeRoot,
            categories: [
                "Included": ["match.avatar"],
                "Excluded": ["match.avatar"],
            ])
        let env = try! makeOutfitPickerSUT(
            config: config, fileSystem: fs.contents, directories: Array(fs.directories))

        let results = try await env.sut.searchOutfits(pattern: "match")

        #expect(results.count == 1)
        #expect(results[0].category.name == "Included")
    }

    @Test func searchOutfits_WithConfigError_ThrowsInvalidConfiguration() async {
        let configSvc = FakeConfigService(.throwsError(ConfigError.pathTraversalNotAllowed))
        let env = OutfitPickerTestEnv(
            sut: OutfitPicker(
                configService: configSvc, cacheService: FakeCacheService(.ok(OutfitCache())),
                fileManager: FakeFileManager(.ok([:]), directories: [])),
            fileManager: FakeFileManager(.ok([:]), directories: []),
            cache: FakeCacheService(.ok(OutfitCache())),
            config: configSvc
        )

        do {
            _ = try await env.sut.searchOutfits(pattern: "test")
            Issue.record("Expected invalidConfiguration error")
        } catch OutfitPickerError.invalidConfiguration {
            // Expected
        } catch {
            Issue.record("Expected invalidConfiguration error, got \(error)")
        }
    }

    // MARK: - filterCategories Tests

    @Test func filterCategories_WithEmptyPattern_ThrowsInvalidInput() async {
        let env = try! makeOutfitPickerSUT()

        do {
            _ = try await env.sut.filterCategories(pattern: "")
            Issue.record("Expected invalidInput error")
        } catch OutfitPickerError.invalidInput(let message) {
            #expect(message == "Filter pattern cannot be empty")
        } catch {
            Issue.record("Expected invalidInput error, got \(error)")
        }
    }

    @Test func filterCategories_WithMatchingCategories_ReturnsMatches() async throws {
        let fs = makeFS(
            root: safeRoot,
            categories: [
                "Summer_Casual": ["outfit1.avatar"],
                "Winter_Formal": ["outfit2.avatar"],
                "Spring_Casual": ["outfit3.avatar"],
                "Business": ["outfit4.avatar"],
            ])
        let env = try! makeOutfitPickerSUT(
            fileSystem: fs.contents, directories: Array(fs.directories))

        let results = try await env.sut.filterCategories(pattern: "Casual")

        #expect(results.count == 2)
        #expect(results.contains { $0.name == "Summer_Casual" })
        #expect(results.contains { $0.name == "Spring_Casual" })
    }

    @Test func filterCategories_CaseInsensitive_ReturnsMatches() async throws {
        let fs = makeFS(
            root: safeRoot,
            categories: [
                "FORMAL": ["outfit1.avatar"],
                "casual": ["outfit2.avatar"],
            ])
        let env = try! makeOutfitPickerSUT(
            fileSystem: fs.contents, directories: Array(fs.directories))

        let results = try await env.sut.filterCategories(pattern: "formal")

        #expect(results.count == 1)
        #expect(results[0].name == "FORMAL")
    }

    @Test func filterCategories_WithNoMatches_ReturnsEmpty() async throws {
        let fs = makeFS(
            root: safeRoot,
            categories: [
                "Category1": ["outfit1.avatar"],
                "Category2": ["outfit2.avatar"],
            ])
        let env = try! makeOutfitPickerSUT(
            fileSystem: fs.contents, directories: Array(fs.directories))

        let results = try await env.sut.filterCategories(pattern: "nonexistent")

        #expect(results.isEmpty)
    }

    @Test func filterCategories_ResultsSortedByName() async throws {
        let fs = makeFS(
            root: safeRoot,
            categories: [
                "Zebra_Style": ["outfit1.avatar"],
                "Alpha_Style": ["outfit2.avatar"],
                "Beta_Style": ["outfit3.avatar"],
            ])
        let env = try! makeOutfitPickerSUT(
            fileSystem: fs.contents, directories: Array(fs.directories))

        let results = try await env.sut.filterCategories(pattern: "Style")

        #expect(results.count == 3)
        #expect(results[0].name == "Alpha_Style")
        #expect(results[1].name == "Beta_Style")
        #expect(results[2].name == "Zebra_Style")
    }

    @Test func filterCategories_OnlyIncludesHasOutfitsCategories() async throws {
        let fs = makeFS(
            root: safeRoot,
            categories: [
                "HasOutfits": ["outfit.avatar"],
                "Empty": [],
            ])
        let env = try! makeOutfitPickerSUT(
            fileSystem: fs.contents, directories: Array(fs.directories))

        // Test that only categories with outfits are included
        let results = try await env.sut.filterCategories(pattern: "Has")
        #expect(results.count == 1)
        #expect(results[0].name == "HasOutfits")

        // Test that empty categories are not included even if they match the pattern
        let emptyResults = try await env.sut.filterCategories(pattern: "Empty")
        #expect(emptyResults.isEmpty)
    }

    @Test func filterCategories_WithConfigError_ThrowsInvalidConfiguration() async {
        let configSvc = FakeConfigService(.throwsError(ConfigError.pathTraversalNotAllowed))
        let env = OutfitPickerTestEnv(
            sut: OutfitPicker(
                configService: configSvc, cacheService: FakeCacheService(.ok(OutfitCache())),
                fileManager: FakeFileManager(.ok([:]), directories: [])),
            fileManager: FakeFileManager(.ok([:]), directories: []),
            cache: FakeCacheService(.ok(OutfitCache())),
            config: configSvc
        )

        do {
            _ = try await env.sut.filterCategories(pattern: "test")
            Issue.record("Expected invalidConfiguration error")
        } catch OutfitPickerError.invalidConfiguration {
            // Expected
        } catch {
            Issue.record("Expected invalidConfiguration error, got \(error)")
        }
    }
}
