import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct CategoryTests {

    private func validateCategoryName(_ path: String, expected: String) {
        let category = Category(path: path, outfits: [])
        let foundationExpected = URL(
            filePath: path,
            directoryHint: .isDirectory
        ).lastPathComponent
        #expect(category.name == expected)
        #expect(category.name == foundationExpected)
    }

    private func validateFileEntry(
        _ filePath: String,
        expectedFile: String,
        expectedName: String
    ) {
        let entry = FileEntry(filePath: filePath)
        let url = URL(filePath: filePath, directoryHint: .notDirectory)
        let expectedDir = url.deletingLastPathComponent().path(
            percentEncoded: false
        )

        #expect(entry.categoryPath == expectedDir)
        #expect(entry.fileName == expectedFile)
        #expect(entry.categoryName == expectedName)
        #expect(entry.fileName == url.lastPathComponent)
    }

    // MARK: - Category.name

    @Test("Category name extraction (platform-specific)")
    func categoryNameExtraction() {
        #if os(Windows)
            let testCases = [
                ("C:\\Users\\John\\outfits\\casual", "casual"),
                ("C:/Users/John/outfits/formal", "formal"),
                ("\\\\server\\share\\outfits\\summer", "summer"),
                ("C:\\single", "single"),
                ("noseparator", "noseparator"),
                (
                    "C:\\Users\\John Doe\\My Outfits\\posh leather",
                    "posh leather"
                ),
                ("C:\\Users\\John\\outfits\\casual\\", "casual"),
            ]
        #else
            let testCases = [
                ("/Users/john/outfits/casual", "casual"),
                ("/home/user/clothes/formal", "formal"),
                (".outfits/summer", "summer"),
                ("relative/path/winter", "winter"),
                ("/single", "single"),
                ("noseparator", "noseparator"),
                ("/Users/john doe/My Outfits/posh leather", "posh leather"),
                ("/Users/john/outfits/casual/", "casual"),
            ]
        #endif

        for (path, expected) in testCases {
            validateCategoryName(path, expected: expected)
        }
    }

    // MARK: - FileEntry basics (categoryPath, fileName, categoryName)

    @Test("FileEntry properties (platform-specific)")
    func fileEntryProperties() {
        #if os(Windows)
            let testCases = [
                (
                    "C:\\Users\\John\\outfits\\casual\\outfit1.avatar",
                    "outfit1.avatar", "casual"
                ),
                (
                    "C:/Users/John/outfits/formal/suit.avatar", "suit.avatar",
                    "formal"
                ),
                (
                    "\\\\server\\share\\outfits\\summer\\shorts.avatar",
                    "shorts.avatar", "summer"
                ),
            ]
        #else
            let testCases = [
                (
                    "/Users/john/outfits/casual/outfit1.avatar",
                    "outfit1.avatar", "casual"
                ),
                (
                    "/home/user/clothes/formal/suit.avatar", "suit.avatar",
                    "formal"
                ),
                (
                    "/Users/john doe/My Outfits/summer clothes/blue shirt.avatar",
                    "blue shirt.avatar", "summer clothes"
                ),
                ("relative/path/winter/wool.avatar", "wool.avatar", "winter"),
            ]
        #endif

        for (filePath, expectedFile, expectedName) in testCases {
            validateFileEntry(
                filePath,
                expectedFile: expectedFile,
                expectedName: expectedName
            )
        }
    }

    // MARK: - Additional focused checks

    @Test
    func categoryName_fromFileEntry() {
        #if os(Windows)
            let entry = FileEntry(filePath: "C:\\outfits\\casual\\shirt.avatar")
        #else
            let entry = FileEntry(filePath: "/outfits/casual/shirt.avatar")
        #endif
        #expect(entry.categoryName == "casual")
    }

    @Test
    func categoryPath_fromFileEntry() {
        #if os(Windows)
            let entry = FileEntry(filePath: "C:\\outfits\\casual\\shirt.avatar")
            let expected = "C:\\outfits\\casual"
        #else
            let entry = FileEntry(filePath: "/outfits/casual/shirt.avatar")
            let expected = "/outfits/casual/"
        #endif
        #expect(entry.categoryPath == expected)
    }

    @Test
    func unicodeAndSpacesArePreserved() {
        #if os(Windows)
            let dir = "C:\\Users\\Jöhn Dœ\\My Outfits\\春 夏"
            let file = dir + "\\花 avatar.avatar"
        #else
            let dir = "/Users/jöhn døe/My Outfits/春 夏"
            let file = dir + "/花 avatar.avatar"
        #endif

        let expectedDirName = URL(filePath: dir, directoryHint: .isDirectory)
            .lastPathComponent
        let expectedFileName = URL(filePath: file, directoryHint: .notDirectory)
            .lastPathComponent

        validateCategoryName(dir, expected: expectedDirName)
        validateFileEntry(
            file,
            expectedFile: expectedFileName,
            expectedName: expectedDirName
        )
    }
}
