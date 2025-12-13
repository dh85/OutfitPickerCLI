//! Test support module with reusable mocks and fixtures.
//!
//! This module provides test doubles and utilities for testing
//! the outfit picker application.

use async_trait::async_trait;
use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};

use crate::domain::error::{CacheError, FileSystemError, OutfitPickerError, Result};
use crate::domain::models::{
    CategoryCache, CategoryInfo, CategoryReference, CategoryState, Config, FileEntry, OutfitCache,
};
use crate::domain::ports::{CacheRepositoryPort, CategoryScannerPort, ConfigRepositoryPort};

// ============================================================================
// Fake Cache Repository
// ============================================================================

/// A fake cache repository for testing.
#[derive(Clone, Default)]
pub struct FakeCacheRepository {
    cache: Arc<Mutex<OutfitCache>>,
    should_fail_load: Arc<Mutex<bool>>,
    should_fail_save: Arc<Mutex<bool>>,
    save_count: Arc<Mutex<usize>>,
}

impl FakeCacheRepository {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_cache(cache: OutfitCache) -> Self {
        Self {
            cache: Arc::new(Mutex::new(cache)),
            ..Default::default()
        }
    }

    pub fn fail_on_load(&self) {
        *self.should_fail_load.lock().unwrap() = true;
    }

    pub fn fail_on_save(&self) {
        *self.should_fail_save.lock().unwrap() = true;
    }

    pub fn save_count(&self) -> usize {
        *self.save_count.lock().unwrap()
    }

    pub fn get_cache(&self) -> OutfitCache {
        self.cache.lock().unwrap().clone()
    }
}

#[async_trait]
impl CacheRepositoryPort for FakeCacheRepository {
    async fn load(&self) -> Result<OutfitCache> {
        if *self.should_fail_load.lock().unwrap() {
            return Err(CacheError::DecodingFailed.into());
        }
        Ok(self.cache.lock().unwrap().clone())
    }

    async fn save(&self, cache: &OutfitCache) -> Result<()> {
        if *self.should_fail_save.lock().unwrap() {
            return Err(CacheError::EncodingFailed.into());
        }
        *self.cache.lock().unwrap() = cache.clone();
        *self.save_count.lock().unwrap() += 1;
        Ok(())
    }

    async fn delete(&self) -> Result<()> {
        *self.cache.lock().unwrap() = OutfitCache::new();
        Ok(())
    }
}

// ============================================================================
// Fake Config Repository
// ============================================================================

/// A fake config repository for testing.
#[derive(Clone)]
pub struct FakeConfigRepository {
    config: Arc<Mutex<Option<Config>>>,
    should_fail_load: Arc<Mutex<bool>>,
    should_fail_save: Arc<Mutex<bool>>,
}

impl Default for FakeConfigRepository {
    fn default() -> Self {
        Self {
            config: Arc::new(Mutex::new(None)),
            should_fail_load: Arc::new(Mutex::new(false)),
            should_fail_save: Arc::new(Mutex::new(false)),
        }
    }
}

impl FakeConfigRepository {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_config(config: Config) -> Self {
        Self {
            config: Arc::new(Mutex::new(Some(config))),
            ..Default::default()
        }
    }

    pub fn fail_on_load(&self) {
        *self.should_fail_load.lock().unwrap() = true;
    }

    pub fn fail_on_save(&self) {
        *self.should_fail_save.lock().unwrap() = true;
    }
}

#[async_trait]
impl ConfigRepositoryPort for FakeConfigRepository {
    async fn load(&self) -> Result<Config> {
        if *self.should_fail_load.lock().unwrap() {
            return Err(FileSystemError::FileNotFound("config.json".into()).into());
        }
        self.config
            .lock()
            .unwrap()
            .clone()
            .ok_or_else(|| FileSystemError::FileNotFound("config.json".into()).into())
    }

    async fn save(&self, config: &Config) -> Result<()> {
        if *self.should_fail_save.lock().unwrap() {
            return Err(FileSystemError::OperationFailed("Save failed".into()).into());
        }
        *self.config.lock().unwrap() = Some(config.clone());
        Ok(())
    }

    async fn delete(&self) -> Result<()> {
        *self.config.lock().unwrap() = None;
        Ok(())
    }

    fn exists(&self) -> bool {
        self.config.lock().unwrap().is_some()
    }
}

// ============================================================================
// Fake Category Scanner
// ============================================================================

/// A fake category scanner for testing.
#[derive(Clone, Default)]
pub struct FakeCategoryScanner {
    categories: Arc<Mutex<Vec<CategoryInfo>>>,
    should_fail: Arc<Mutex<bool>>,
    error_message: Arc<Mutex<String>>,
}

impl FakeCategoryScanner {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_categories(categories: Vec<CategoryInfo>) -> Self {
        Self {
            categories: Arc::new(Mutex::new(categories)),
            ..Default::default()
        }
    }

    pub fn fail_with(&self, message: &str) {
        *self.should_fail.lock().unwrap() = true;
        *self.error_message.lock().unwrap() = message.to_string();
    }

    pub fn set_categories(&self, categories: Vec<CategoryInfo>) {
        *self.categories.lock().unwrap() = categories;
    }
}

#[async_trait]
impl CategoryScannerPort for FakeCategoryScanner {
    async fn scan_categories(
        &self,
        _root: &Path,
        excluded: &HashSet<String>,
    ) -> Result<Vec<CategoryInfo>> {
        if *self.should_fail.lock().unwrap() {
            let msg = self.error_message.lock().unwrap().clone();
            return Err(FileSystemError::OperationFailed(msg).into());
        }

        let categories = self.categories.lock().unwrap().clone();
        
        // Apply exclusions
        Ok(categories
            .into_iter()
            .map(|mut c| {
                if excluded.contains(&c.category.name) {
                    c.state = CategoryState::UserExcluded;
                }
                c
            })
            .collect())
    }
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Creates a test configuration.
pub fn test_config(root: impl Into<PathBuf>) -> Config {
    Config {
        root: root.into(),
        language: Some("en".to_string()),
        excluded_categories: HashSet::new(),
        known_categories: HashSet::new(),
        known_category_files: HashMap::new(),
    }
}

/// Creates a test category info.
pub fn test_category(name: &str, outfit_count: usize) -> CategoryInfo {
    CategoryInfo::new(
        CategoryReference::new(name, PathBuf::from(format!("/test/{}", name))),
        CategoryState::HasOutfits,
        outfit_count,
    )
}

/// Creates a test file entry.
pub fn test_file_entry(category: &str, file_name: &str) -> FileEntry {
    FileEntry::new(PathBuf::from(format!("/test/{}/{}", category, file_name)))
}

/// Creates a cache with worn outfits.
pub fn test_cache_with_worn(category_path: &str, worn: Vec<&str>, total: usize) -> OutfitCache {
    let mut cache = OutfitCache::new();
    let mut category_cache = CategoryCache::new(total);
    for outfit in worn {
        category_cache.add_worn(outfit);
    }
    cache.categories.insert(category_path.to_string(), category_cache);
    cache
}

// ============================================================================
// Assertion Helpers
// ============================================================================

/// Asserts that a result is an InvalidInput error with the expected message.
pub fn assert_invalid_input(result: Result<()>, expected_message: &str) {
    match result {
        Err(OutfitPickerError::InvalidInput(msg)) => {
            assert!(
                msg.contains(expected_message),
                "Expected message containing '{}', got '{}'",
                expected_message,
                msg
            );
        }
        other => panic!("Expected InvalidInput error, got {:?}", other),
    }
}

/// Asserts that a result is a CategoryNotFound error.
pub fn assert_category_not_found(result: Result<()>, category: &str) {
    match result {
        Err(OutfitPickerError::CategoryNotFound(name)) => {
            assert_eq!(name, category);
        }
        other => panic!("Expected CategoryNotFound error, got {:?}", other),
    }
}

/// Asserts that a result is a NoOutfitsAvailable error.
pub fn assert_no_outfits_available<T: std::fmt::Debug>(result: Result<T>) {
    match result {
        Err(OutfitPickerError::NoOutfitsAvailable) => {}
        other => panic!("Expected NoOutfitsAvailable error, got {:?}", other),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ============================================================================
    // FakeCacheRepository Tests
    // ============================================================================

    #[tokio::test]
    async fn test_fake_cache_repository_load_save() {
        let repo = FakeCacheRepository::new();
        
        let cache = repo.load().await.unwrap();
        assert!(cache.categories.is_empty());
        
        let mut new_cache = OutfitCache::new();
        new_cache.get_or_create("/test/Category1", 5);
        
        repo.save(&new_cache).await.unwrap();
        assert_eq!(repo.save_count(), 1);
        
        let loaded = repo.load().await.unwrap();
        assert!(loaded.categories.contains_key("/test/Category1"));
    }

    #[tokio::test]
    async fn test_fake_cache_repository_fail_on_load() {
        let repo = FakeCacheRepository::new();
        repo.fail_on_load();
        
        let result = repo.load().await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_fake_cache_repository_fail_on_save() {
        let repo = FakeCacheRepository::new();
        repo.fail_on_save();
        
        let cache = OutfitCache::new();
        let result = repo.save(&cache).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_fake_cache_repository_delete() {
        let cache = test_cache_with_worn("/test/Cat", vec!["outfit.avatar"], 5);
        let repo = FakeCacheRepository::with_cache(cache);
        
        // Cache should have data
        let loaded = repo.load().await.unwrap();
        assert!(!loaded.categories.is_empty());
        
        // Delete should clear it
        repo.delete().await.unwrap();
        
        let loaded = repo.load().await.unwrap();
        assert!(loaded.categories.is_empty());
    }

    #[tokio::test]
    async fn test_fake_cache_repository_multiple_saves() {
        let repo = FakeCacheRepository::new();
        
        let cache = OutfitCache::new();
        repo.save(&cache).await.unwrap();
        repo.save(&cache).await.unwrap();
        repo.save(&cache).await.unwrap();
        
        assert_eq!(repo.save_count(), 3);
    }

    #[tokio::test]
    async fn test_fake_cache_repository_with_cache() {
        let initial = test_cache_with_worn("/test/Cat", vec!["a.avatar", "b.avatar"], 5);
        let repo = FakeCacheRepository::with_cache(initial);
        
        let loaded = repo.load().await.unwrap();
        let category = loaded.categories.get("/test/Cat").unwrap();
        assert_eq!(category.worn_outfits.len(), 2);
        assert_eq!(category.total_outfits, 5);
    }

    // ============================================================================
    // FakeConfigRepository Tests
    // ============================================================================

    #[tokio::test]
    async fn test_fake_config_repository() {
        let config = test_config("/test/root");
        let repo = FakeConfigRepository::with_config(config.clone());
        
        assert!(repo.exists());
        
        let loaded = repo.load().await.unwrap();
        assert_eq!(loaded.root, config.root);
    }

    #[tokio::test]
    async fn test_fake_config_repository_empty() {
        let repo = FakeConfigRepository::new();
        
        assert!(!repo.exists());
        
        let result = repo.load().await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_fake_config_repository_save_then_load() {
        let repo = FakeConfigRepository::new();
        
        let config = test_config("/test/path");
        repo.save(&config).await.unwrap();
        
        assert!(repo.exists());
        
        let loaded = repo.load().await.unwrap();
        assert_eq!(loaded.root, config.root);
    }

    #[tokio::test]
    async fn test_fake_config_repository_delete() {
        let config = test_config("/test/root");
        let repo = FakeConfigRepository::with_config(config);
        
        assert!(repo.exists());
        
        repo.delete().await.unwrap();
        
        assert!(!repo.exists());
    }

    #[tokio::test]
    async fn test_fake_config_repository_fail_on_load() {
        let repo = FakeConfigRepository::new();
        repo.fail_on_load();
        
        let result = repo.load().await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_fake_config_repository_fail_on_save() {
        let repo = FakeConfigRepository::new();
        repo.fail_on_save();
        
        let config = test_config("/test/root");
        let result = repo.save(&config).await;
        assert!(result.is_err());
    }

    // ============================================================================
    // FakeCategoryScanner Tests
    // ============================================================================

    #[tokio::test]
    async fn test_fake_category_scanner() {
        let categories = vec![
            test_category("Category1", 5),
            test_category("Category2", 3),
        ];
        
        let scanner = FakeCategoryScanner::with_categories(categories);
        let result = scanner
            .scan_categories(Path::new("/test"), &HashSet::new())
            .await
            .unwrap();
        
        assert_eq!(result.len(), 2);
        assert_eq!(result[0].category.name, "Category1");
    }

    #[tokio::test]
    async fn test_fake_category_scanner_with_exclusions() {
        let categories = vec![
            test_category("Category1", 5),
            test_category("Category2", 3),
        ];
        
        let scanner = FakeCategoryScanner::with_categories(categories);
        let mut excluded = HashSet::new();
        excluded.insert("Category1".to_string());
        
        let result = scanner
            .scan_categories(Path::new("/test"), &excluded)
            .await
            .unwrap();
        
        assert_eq!(result[0].state, CategoryState::UserExcluded);
        assert_eq!(result[1].state, CategoryState::HasOutfits);
    }

    #[tokio::test]
    async fn test_fake_category_scanner_empty() {
        let scanner = FakeCategoryScanner::new();
        let result = scanner
            .scan_categories(Path::new("/test"), &HashSet::new())
            .await
            .unwrap();
        
        assert!(result.is_empty());
    }

    #[tokio::test]
    async fn test_fake_category_scanner_fail_with() {
        let scanner = FakeCategoryScanner::new();
        scanner.fail_with("Test error message");
        
        let result = scanner
            .scan_categories(Path::new("/test"), &HashSet::new())
            .await;
        
        match result {
            Err(OutfitPickerError::FileSystem(FileSystemError::OperationFailed(msg))) => {
                assert_eq!(msg, "Test error message");
            }
            _ => panic!("Expected FileSystem error"),
        }
    }

    #[tokio::test]
    async fn test_fake_category_scanner_set_categories() {
        let scanner = FakeCategoryScanner::new();
        
        // Initially empty
        let result = scanner
            .scan_categories(Path::new("/test"), &HashSet::new())
            .await
            .unwrap();
        assert!(result.is_empty());
        
        // Set categories
        scanner.set_categories(vec![test_category("NewCat", 10)]);
        
        let result = scanner
            .scan_categories(Path::new("/test"), &HashSet::new())
            .await
            .unwrap();
        assert_eq!(result.len(), 1);
        assert_eq!(result[0].category.name, "NewCat");
    }

    // ============================================================================
    // Fixture Tests
    // ============================================================================

    #[test]
    fn test_test_config() {
        let config = test_config("/my/path");
        assert_eq!(config.root, PathBuf::from("/my/path"));
        assert_eq!(config.language, Some("en".to_string()));
    }

    #[test]
    fn test_test_category() {
        let cat = test_category("TestCat", 42);
        assert_eq!(cat.category.name, "TestCat");
        assert_eq!(cat.outfit_count, 42);
        assert_eq!(cat.state, CategoryState::HasOutfits);
    }

    #[test]
    fn test_test_file_entry() {
        let entry = test_file_entry("Category1", "outfit.avatar");
        assert_eq!(entry.file_name, "outfit.avatar");
        assert_eq!(entry.category_name, "Category1");
    }

    #[test]
    fn test_test_cache_with_worn() {
        let cache = test_cache_with_worn("/test/Cat", vec!["a.avatar", "b.avatar"], 5);
        let cat = cache.categories.get("/test/Cat").unwrap();
        assert!(cat.worn_outfits.contains("a.avatar"));
        assert!(cat.worn_outfits.contains("b.avatar"));
        assert_eq!(cat.total_outfits, 5);
    }

    // ============================================================================
    // Assertion Helper Tests
    // ============================================================================

    #[test]
    fn test_assert_invalid_input_passes() {
        let result: Result<()> = Err(OutfitPickerError::InvalidInput("test message".into()));
        assert_invalid_input(result, "test");
    }

    #[test]
    #[should_panic(expected = "Expected InvalidInput error")]
    fn test_assert_invalid_input_fails_on_wrong_error() {
        let result: Result<()> = Err(OutfitPickerError::NoOutfitsAvailable);
        assert_invalid_input(result, "test");
    }

    #[test]
    fn test_assert_category_not_found_passes() {
        let result: Result<()> = Err(OutfitPickerError::CategoryNotFound("Cat1".into()));
        assert_category_not_found(result, "Cat1");
    }

    #[test]
    fn test_assert_no_outfits_available_passes() {
        let result: Result<()> = Err(OutfitPickerError::NoOutfitsAvailable);
        assert_no_outfits_available(result);
    }
}
