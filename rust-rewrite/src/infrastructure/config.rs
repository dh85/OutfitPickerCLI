//! Configuration management.
//!
//! This module handles loading and saving the application configuration.

use std::path::{Path, PathBuf};
use tokio::fs;
use async_trait::async_trait;

use crate::domain::error::{CacheError, FileSystemError, Result};
use crate::domain::models::Config;
use crate::domain::ports::ConfigRepositoryPort;

/// Default config file name.
const CONFIG_FILE_NAME: &str = "config.json";

/// Default app folder name.
const APP_FOLDER_NAME: &str = "OutfitPicker";

/// Manages configuration persistence.
#[derive(Clone)]
pub struct ConfigService {
    config_path: PathBuf,
}

#[async_trait]
impl ConfigRepositoryPort for ConfigService {
    async fn load(&self) -> Result<Config> {
        self.load().await
    }

    async fn save(&self, config: &Config) -> Result<()> {
        self.save(config).await
    }

    async fn delete(&self) -> Result<()> {
        self.delete().await
    }

    fn exists(&self) -> bool {
        self.exists()
    }
}

impl ConfigService {
    /// Creates a new config service with the default config location.
    pub fn new() -> Result<Self> {
        let config_path = Self::default_config_path()?;
        Ok(Self { config_path })
    }

    /// Creates a config service with a custom path.
    #[allow(dead_code)]
    pub fn with_path(config_path: PathBuf) -> Self {
        Self { config_path }
    }

    /// Returns the default config path based on the OS.
    fn default_config_path() -> Result<PathBuf> {
        let base_dir = if let Ok(xdg) = std::env::var("XDG_CONFIG_HOME") {
            PathBuf::from(xdg)
        } else if cfg!(target_os = "macos") {
            dirs::data_local_dir()
                .ok_or_else(|| FileSystemError::DirectoryNotFound("Application Support".into()))?
        } else {
            dirs::config_dir()
                .ok_or_else(|| FileSystemError::DirectoryNotFound("config directory".into()))?
        };

        Ok(base_dir.join(APP_FOLDER_NAME).join(CONFIG_FILE_NAME))
    }

    /// Loads the configuration from disk.
    pub async fn load(&self) -> Result<Config> {
        let contents = fs::read_to_string(&self.config_path)
            .await
            .map_err(|_| FileSystemError::FileNotFound(self.config_path.to_string_lossy().to_string()))?;

        let config: Config =
            serde_json::from_str(&contents).map_err(|_| CacheError::DecodingFailed)?;

        Ok(config)
    }

    /// Saves the configuration to disk.
    pub async fn save(&self, config: &Config) -> Result<()> {
        // Ensure parent directory exists
        if let Some(parent) = self.config_path.parent() {
            fs::create_dir_all(parent).await.map_err(|e| {
                FileSystemError::OperationFailed(format!("Failed to create config directory: {}", e))
            })?;
        }

        let contents =
            serde_json::to_string_pretty(config).map_err(|_| CacheError::EncodingFailed)?;

        fs::write(&self.config_path, contents)
            .await
            .map_err(|e| FileSystemError::OperationFailed(format!("Failed to write config: {}", e)))?;

        Ok(())
    }

    /// Deletes the configuration file.
    pub async fn delete(&self) -> Result<()> {
        if self.config_path.exists() {
            fs::remove_file(&self.config_path).await.map_err(|e| {
                FileSystemError::OperationFailed(format!("Failed to delete config: {}", e))
            })?;
        }
        Ok(())
    }

    /// Checks if a configuration file exists.
    #[allow(dead_code)]
    pub fn exists(&self) -> bool {
        self.config_path.exists()
    }

    /// Returns the config file path.
    #[allow(dead_code)]
    pub fn config_path(&self) -> &Path {
        &self.config_path
    }
}

impl Default for ConfigService {
    fn default() -> Self {
        Self::new().expect("Failed to create default config service")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[tokio::test]
    async fn test_save_and_load_roundtrip() {
        let temp = TempDir::new().unwrap();
        let config_path = temp.path().join("config.json");
        let service = ConfigService::with_path(config_path);

        let config = Config::new(temp.path(), Some("en".to_string())).unwrap();

        service.save(&config).await.unwrap();
        let loaded = service.load().await.unwrap();

        assert_eq!(loaded.root, config.root);
        assert_eq!(loaded.language, Some("en".to_string()));
    }

    #[tokio::test]
    async fn test_load_missing_returns_error() {
        let temp = TempDir::new().unwrap();
        let config_path = temp.path().join("nonexistent.json");
        let service = ConfigService::with_path(config_path);

        assert!(service.load().await.is_err());
    }

    #[tokio::test]
    async fn test_exists_returns_false_for_missing() {
        let temp = TempDir::new().unwrap();
        let config_path = temp.path().join("nonexistent.json");
        let service = ConfigService::with_path(config_path);

        assert!(!service.exists());
    }

    #[tokio::test]
    async fn test_exists_returns_true_after_save() {
        let temp = TempDir::new().unwrap();
        let config_path = temp.path().join("config.json");
        let service = ConfigService::with_path(config_path);

        assert!(!service.exists());

        let config = Config::new(temp.path(), Some("en".to_string())).unwrap();
        service.save(&config).await.unwrap();

        assert!(service.exists());
    }

    #[tokio::test]
    async fn test_delete_removes_config() {
        let temp = TempDir::new().unwrap();
        let config_path = temp.path().join("config.json");
        let service = ConfigService::with_path(config_path);

        let config = Config::new(temp.path(), Some("en".to_string())).unwrap();
        service.save(&config).await.unwrap();
        assert!(service.exists());

        service.delete().await.unwrap();
        assert!(!service.exists());
    }

    #[tokio::test]
    async fn test_delete_nonexistent_succeeds() {
        let temp = TempDir::new().unwrap();
        let config_path = temp.path().join("nonexistent.json");
        let service = ConfigService::with_path(config_path);

        // Should not error
        let result = service.delete().await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_config_path_getter() {
        let path = PathBuf::from("/test/config.json");
        let service = ConfigService::with_path(path.clone());

        assert_eq!(service.config_path(), path);
    }

    #[tokio::test]
    async fn test_save_creates_parent_directories() {
        let temp = TempDir::new().unwrap();
        let config_path = temp.path().join("nested/dirs/config.json");
        let service = ConfigService::with_path(config_path.clone());

        let config = Config::new(temp.path(), Some("en".to_string())).unwrap();
        service.save(&config).await.unwrap();

        assert!(config_path.exists());
    }
}
