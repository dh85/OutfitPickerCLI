import Foundation
import Testing

@testable import OutfitPickerCore

@Suite
struct BusinessRulesTests {

    @Test func outfitFileExtension_isAvatar() {
        #expect(BusinessRules.outfitFileExtension == "avatar")
    }

    @Test func defaultLanguage_isEnglish() {
        #expect(BusinessRules.defaultLanguage == "en")
    }

    @Test func isValidOutfitFile_checksExtension() {
        #expect(BusinessRules.isValidOutfitFile("outfit.avatar"))
        #expect(BusinessRules.isValidOutfitFile("OUTFIT.AVATAR"))
        #expect(!BusinessRules.isValidOutfitFile("outfit.txt"))
        #expect(!BusinessRules.isValidOutfitFile("outfit"))
    }

    @Test func isValidCategoryName_checksNonEmpty() {
        #expect(BusinessRules.isValidCategoryName("casual"))
        #expect(!BusinessRules.isValidCategoryName(""))
        #expect(!BusinessRules.isValidCategoryName("   "))
        #expect(!BusinessRules.isValidCategoryName("\t\n"))
    }

    @Test func isValidOutfitFileName_checksNonEmpty() {
        #expect(BusinessRules.isValidOutfitFileName("outfit.avatar"))
        #expect(!BusinessRules.isValidOutfitFileName(""))
        #expect(!BusinessRules.isValidOutfitFileName("   "))
    }

    @Test func shouldResetRotation_checksWornCount() {
        #expect(BusinessRules.shouldResetRotation(wornCount: 5, totalCount: 5))
        #expect(BusinessRules.shouldResetRotation(wornCount: 6, totalCount: 5))
        #expect(!BusinessRules.shouldResetRotation(wornCount: 3, totalCount: 5))
    }

    @Test func calculateProgress_returnsCorrectPercentage() {
        #expect(BusinessRules.calculateProgress(wornCount: 0, totalCount: 10) == 0.0)
        #expect(BusinessRules.calculateProgress(wornCount: 5, totalCount: 10) == 0.5)
        #expect(BusinessRules.calculateProgress(wornCount: 10, totalCount: 10) == 1.0)
        #expect(BusinessRules.calculateProgress(wornCount: 0, totalCount: 0) == 1.0)
    }

    @Test func isRotationComplete_checksCompletion() {
        #expect(BusinessRules.isRotationComplete(wornCount: 5, totalCount: 5))
        #expect(BusinessRules.isRotationComplete(wornCount: 6, totalCount: 5))
        #expect(!BusinessRules.isRotationComplete(wornCount: 3, totalCount: 5))
    }

    @Test func filterOutfitFiles_onlyIncludesAvatarFiles() {
        let urls = [
            URL(filePath: "/test/outfit1.avatar"),
            URL(filePath: "/test/readme.txt"),
            URL(filePath: "/test/outfit2.avatar"),
            URL(filePath: "/test/subdir/"),
        ]

        let outfits = BusinessRules.filterOutfitFiles(from: urls)
        #expect(outfits.count == 2)
        #expect(outfits[0].fileName == "outfit1.avatar")
        #expect(outfits[1].fileName == "outfit2.avatar")
    }

    @Test func filterAvailableOutfits_excludesWornOutfits() {
        let files = [
            FileEntry(filePath: "/test/outfit1.avatar"),
            FileEntry(filePath: "/test/outfit2.avatar"),
            FileEntry(filePath: "/test/outfit3.avatar"),
        ]
        let wornOutfits: Set<String> = ["outfit1.avatar", "outfit3.avatar"]

        let available = BusinessRules.filterAvailableOutfits(from: files, wornOutfits: wornOutfits)
        #expect(available.count == 1)
        #expect(available[0].fileName == "outfit2.avatar")
    }

    @Test func isCategoryEmpty_returnsTrueWhenBothEmpty() {
        #expect(BusinessRules.isCategoryEmpty(avatarFiles: [], allFiles: []))
    }

    @Test func isCategoryEmpty_returnsFalseWhenAvatarFilesExist() {
        let avatarFiles = [FileEntry(filePath: "/test/outfit.avatar")]
        #expect(!BusinessRules.isCategoryEmpty(avatarFiles: avatarFiles, allFiles: []))
    }

    @Test func isCategoryEmpty_returnsFalseWhenOtherFilesExist() {
        let allFiles = [URL(filePath: "/test/readme.txt")]
        #expect(!BusinessRules.isCategoryEmpty(avatarFiles: [], allFiles: allFiles))
    }

    @Test func hasNoAvatarFiles_returnsTrueWhenOnlyOtherFiles() {
        let allFiles = [URL(filePath: "/test/readme.txt")]
        #expect(BusinessRules.hasNoAvatarFiles(avatarFiles: [], allFiles: allFiles))
    }

    @Test func hasNoAvatarFiles_returnsFalseWhenAvatarFilesExist() {
        let avatarFiles = [FileEntry(filePath: "/test/outfit.avatar")]
        let allFiles = [URL(filePath: "/test/readme.txt")]
        #expect(!BusinessRules.hasNoAvatarFiles(avatarFiles: avatarFiles, allFiles: allFiles))
    }

    @Test func hasNoAvatarFiles_returnsFalseWhenBothEmpty() {
        #expect(!BusinessRules.hasNoAvatarFiles(avatarFiles: [], allFiles: []))
    }
}
