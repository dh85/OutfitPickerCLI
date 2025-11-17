import Testing
@testable import OutfitPickerCLI

struct OutfitSessionTests {
    
    @Test func globalSkippedTracking() {
        var session = OutfitSession()
        
        #expect(!session.isGloballySkipped("outfit1"))
        
        session.addSkipped("outfit1")
        #expect(session.isGloballySkipped("outfit1"))
        #expect(session.globalSkippedCount() == 1)
        
        session.resetGlobal()
        #expect(!session.isGloballySkipped("outfit1"))
        #expect(session.globalSkippedCount() == 0)
    }
    
    @Test func categorySkippedTracking() {
        var session = OutfitSession()
        
        #expect(!session.isCategorySkipped("outfit1", category: "casual"))
        
        session.addCategorySkipped("outfit1", category: "casual")
        #expect(session.isCategorySkipped("outfit1", category: "casual"))
        #expect(!session.isCategorySkipped("outfit1", category: "formal"))
        #expect(session.categorySkippedCount("casual") == 1)
        
        session.resetCategory("casual")
        #expect(!session.isCategorySkipped("outfit1", category: "casual"))
        #expect(session.categorySkippedCount("casual") == 0)
    }
}