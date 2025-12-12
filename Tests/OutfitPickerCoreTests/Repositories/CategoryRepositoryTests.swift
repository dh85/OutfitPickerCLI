import Testing
import Foundation
@testable import OutfitPickerCore
import OutfitPickerTestSupport

@Suite("CategoryRepository Tests")
struct CategoryRepositoryTests {
    
    @Test("getCategories delegates to scanner")
    func getCategories() async throws {
        let categoryInfo = CategoryInfo(
            category: CategoryReference(name: "casual", path: "/test/casual"),
            state: .hasOutfits,
            outfitCount: 2
        )
        let scanner = FakeCategoryScanner(categoryInfos: [categoryInfo])
        let repository = CategoryRepository(categoryScanner: scanner)
        
        let result = try await repository.getCategories(in: "/test", excludedCategories: [])
        
        #expect(result.count == 1)
        #expect(result[0].category.name == "casual")
    }
    
    @Test("getCategories passes excluded categories to scanner")
    func getCategoriesWithExclusions() async throws {
        let scanner = FakeCategoryScanner(categoryInfos: [])
        let repository = CategoryRepository(categoryScanner: scanner)
        
        let result = try await repository.getCategories(in: "/test", excludedCategories: ["old"])
        
        #expect(result.isEmpty)
    }
    
    @Test("getCategories throws when scanner throws")
    func getCategoriesThrows() async throws {
        let scanner = ThrowingCategoryScanner(OutfitPickerError.fileSystemError)
        let repository = CategoryRepository(categoryScanner: scanner)
        
        await #expect(throws: OutfitPickerError.self) {
            try await repository.getCategories(in: "/test", excludedCategories: [])
        }
    }
    
    @Test("getOutfits delegates to scanner")
    func getOutfits() async throws {
        let outfits = [
            FileEntry(filePath: "/test/casual/shirt.avatar"),
            FileEntry(filePath: "/test/casual/pants.avatar")
        ]
        let scanner = FakeCategoryScanner(outfitsByPath: ["/test/casual": outfits])
        let repository = CategoryRepository(categoryScanner: scanner)
        
        let result = try await repository.getOutfits(in: "/test/casual")
        
        #expect(result.count == 2)
        #expect(result[0].fileName == "pants.avatar")
        #expect(result[1].fileName == "shirt.avatar")
    }
    
    @Test("getOutfits throws when scanner throws")
    func getOutfitsThrows() async throws {
        let scanner = ThrowingCategoryScanner(OutfitPickerError.fileSystemError)
        let repository = CategoryRepository(categoryScanner: scanner)
        
        await #expect(throws: OutfitPickerError.self) {
            try await repository.getOutfits(in: "/test/casual")
        }
    }
}
