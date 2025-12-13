//! Cache management for outfit tracking.
//!
//! This module handles loading, saving, and managing the outfit cache
//! which tracks which outfits have been worn in each category.

use std::path::{Path, PathBuf};
use tokio::fs;
use async_trait::async_trait;

use crate::domain::error::{CacheError, FileSystemError, Result};
use crate::domain::models::OutfitCache;
use crate::domain::ports::CacheRepositoryPort;

/// Default cache file name.
const CACHE_FILE_NAME: &str = "outfit_cache.json";

/// Default app folder name.
const APP_FOLDER_NAME: &str = "OutfitPicker";

/// Manages the outfit cache persistence.
#[derive(Clone)]
pub struct CacheManager {
    cache_path: PathBuf,
}

#[async_trait]
impl CacheRepositoryPort for CacheManager {
    async fn load(&self) -> Result<OutfitCache> {
        self.load().await
    }

    async fn save(&self, cache: &OutfitCache) -> Result<()> {
        self.save(cache).await
    }

    async fn delete(&self) -> Result<()> {
        self.delete().await
    }
}

impl CacheManager {
    /// Creates a new cache manager with the default cache location.
    pub fn new() -> Result<Self> {
        let cache_path = Self::default_cache_path()?;
        Ok(Self { cache_path })
    }

    /// Creates a cache manager with a custom cache path.
    #[allow(dead_code)]
    pub fn with_path(cache_path: PathBuf) -> Self {
        Self { cache_path }
    }

    /// Returns the default cache path based on the OS.
    fn default_cache_path() -> Result<PathBuf> {
        // Use XDG_CONFIG_HOME on Unix, or Application Support on macOS
        let base_dir = if let Ok(xdg) = std::env::var("XDG_CONFIG_HOME") {
            PathBuf::from(xdg)
        } else if cfg!(target_os = "macos") {
            dirs::data_local_dir()
                .ok_or_else(|| FileSystemError::DirectoryNotFound("Application Support".into()))?
        } else {
            dirs::config_dir()
                .ok_or_else(|| FileSystemError::DirectoryNotFound("config directory".into()))?
        };

        Ok(base_dir.join(APP_FOLDER_NAME).join(CACHE_FILE_NAME))
    }

    /// Loads the cache from disk.
    ///
    /// Returns a default empty cache if the file doesn't exist.
    pub async fn load(&self) -> Result<OutfitCache> {
        if !self.cache_path.exists() {
            return Ok(OutfitCache::new());
        }

        let contents = fs::read_to_string(&self.cache_path)
            .await
            .map_err(|e| FileSystemError::OperationFailed(format!("Failed to read cache: {}", e)))?;

        let cache: OutfitCache =
            serde_json::from_str(&contents).map_err(|_| CacheError::DecodingFailed)?;

        Ok(cache)
    }

    /// Saves the cache to disk.
    pub async fn save(&self, cache: &OutfitCache) -> Result<()> {
        // Ensure parent directory exists
        if let Some(parent) = self.cache_path.parent() {
            fs::create_dir_all(parent).await.map_err(|e| {
                FileSystemError::OperationFailed(format!("Failed to create cache directory: {}", e))
            })?;
        }

        let contents =
            serde_json::to_string_pretty(cache).map_err(|_| CacheError::EncodingFailed)?;

        fs::write(&self.cache_path, contents)
            .await
            .map_err(|e| FileSystemError::OperationFailed(format!("Failed to write cache: {}", e)))?;

        Ok(())
    }

    /// Deletes the cache file.
    pub async fn delete(&self) -> Result<()> {
        if self.cache_path.exists() {
            fs::remove_file(&self.cache_path).await.map_err(|e| {
                FileSystemError::OperationFailed(format!("Failed to delete cache: {}", e))
            })?;
        }
        Ok(())
    }

    /// Returns the cache file path.
    #[allow(dead_code)]
    pub fn cache_path(&self) -> &Path {
        &self.cache_path
    }
}

impl Default for CacheManager {
    fn default() -> Self {
        Self::new().expect("Failed to create default cache manager")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[tokio::test]
    async fn test_load_missing_cache_returns_default() {
        let temp = TempDir::new().unwrap();
        let cache_path = temp.path().join("nonexistent.json");
        let manager = CacheManager::with_path(cache_path);

        let cache = manager.load().await.unwrap();
        assert!(cache.categories.is_empty());
        assert_eq!(cache.version, 1);
    }

    #[tokio::test]
    async fn test_save_and_load_roundtrip() {
        let temp = TempDir::new().unwrap();
        let cache_path = temp.path().join("test_cache.json");
        let manager = CacheManager::with_path(cache_path);

        let mut cache = OutfitCache::new();
        cache.get_or_create("/test/category", 5).add_worn("outfit1.avatar");

        manager.save(&cache).await.unwrap();
        let loaded = manager.load().await.unwrap();

        assert_eq!(loaded.categories.len(), 1);
        assert!(loaded.categories["/test/category"]
            .worn_outfits
            .contains("outfit1.avatar"));
    }

    #[tokio::test]
    async fn test_delete_removes_cache() {
        let temp = TempDir::new().unwrap();
        let cache_path = temp.path().join("to_delete.json");
        let manager = CacheManager::with_path(cache_path.clone());

        manager.save(&OutfitCache::new()).await.unwrap();
        assert!(cache_path.exists());

        manager.delete().await.unwrap();
        assert!(!cache_path.exists());
    }

    #[tokio::test]
    async fn test_delete_nonexistent_file_succeeds() {
        let temp = TempDir::new().unwrap();
        let cache_path = temp.path().join("does_not_exist.json");
        let manager = CacheManager::with_path(cache_path.clone());

        // Deleting a file that doesn't exist should not error
        let result = manager.delete().await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_save_creates_parent_directories() {
        let temp = TempDir::new().unwrap();
        let cache_path = temp.path().join("nested/dirs/cache.json");
        let manager = CacheManager::with_path(cache_path.clone());

        let cache = OutfitCache::new();
        manager.save(&cache).await.unwrap();

        assert!(cache_path.exists());
    }

    #[tokio::test]
    async fn test_cache_path_getter() {
        let path = PathBuf::from("/some/test/path.json");
        let manager = CacheManager::with_path(path.clone());

        assert_eq!(manager.cache_path(), path);
    }

    #[tokio::test]
    async fn test_load_corrupted_cache_returns_error() {
        let temp = TempDir::new().unwrap();
        let cache_path = temp.path().join("corrupted.json");
        
        // Write invalid JSON
        fs::write(&cache_path, "{ invalid json }").await.unwrap();
        
        let manager = CacheManager::with_path(cache_path);
        let result = manager.load().await;
        
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_multiple_saves_overwrite() {
        let temp = TempDir::new().unwrap();
        let cache_path = temp.path().join("test.json");
        let manager = CacheManager::with_path(cache_path);

        // Save with 1 category
        let mut cache = OutfitCache::new();
        cache.get_or_create("/test/cat1", 5);
        manager.save(&cache).await.unwrap();

        // Save with different category
        let mut cache2 = OutfitCache::new();
        cache2.get_or_create("/test/cat2", 10);
        manager.save(&cache2).await.unwrap();

        // Load should get second cache
        let loaded = manager.load().await.unwrap();
        assert!(loaded.categories.contains_key("/test/cat2"));
        assert!(!loaded.categories.contains_key("/test/cat1"));
    }
}
