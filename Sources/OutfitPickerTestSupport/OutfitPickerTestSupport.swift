/// OutfitPicker Test Support Module
///
/// This module provides comprehensive testing utilities for the OutfitPicker library,
/// including fake implementations, test fixtures, and helper functions.
///
/// ## Module Organization
///
/// ### TestHelpers
/// General utility functions for testing:
/// - `uniqueTempDir()` - Creates unique temporary directories
/// - `fileExists(_:)` - Checks file existence
/// - `normPath(_:)` - Normalizes file paths
///
/// ### MockFilesystem
/// Utilities for creating mock filesystem structures:
/// - `makeCategoryDir(root:name:files:)` - Creates single category structure
/// - `makeFS(root:categories:)` - Creates multi-category structure
///
/// ### TestFixtures
/// Pre-configured System Under Test containers:
/// - `SingleCategorySUT` - Container for single-category tests
/// - `AcrossCategoriesSUT` - Container for multi-category tests
/// - Factory functions for easy SUT creation
///
/// ### FakeServices
/// Fake implementations of core protocols:
/// - `FakeConfigService` - Controllable config service
/// - `FakeCacheService` - Controllable cache service with save tracking
/// - `FakeFileManager` - Controllable file manager with filesystem simulation
///
/// ### TestDoubles
/// Specialized test doubles for edge cases:
/// - Directory providers (fixed, throwing)
/// - Data managers (throwing, corrupting, recording)
/// - File managers (throwing on directory creation)
///
/// ## Usage
///
/// Import this module in your test files to access all testing utilities:
///
/// ```swift
/// import OutfitPickerTestSupport
///
/// // Create a test fixture
/// let sut = try makeSingleCategorySUT(
///     category: "casual",
///     files: ["shirt1.avatar", "pants1.avatar"]
/// )
///
/// // Use the configured OutfitPicker
/// let result = sut.sut.showRandomOutfit(from: "casual")
/// ```

@_exported import struct OutfitPickerCore.Config
@_exported import struct OutfitPickerCore.OutfitCache
// Re-export all public APIs from the organized modules
@_exported import class OutfitPickerCore.OutfitPicker
