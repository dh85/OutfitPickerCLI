//! Core business logic for outfit selection.
//!
//! This module contains the main `OutfitPicker` that orchestrates
//! category scanning, cache management, and outfit selection.

use rand::seq::SliceRandom;
use std::path::Path;

use crate::infrastructure::cache::CacheManager;
use crate::infrastructure::config::ConfigService;
use crate::domain::error::{OutfitPickerError, Result};
use crate::domain::models::{CategoryInfo, CategoryState, Config, FileEntry, OutfitSelection};
use crate::infrastructure::fs::scanner::CategoryScanner;
use crate::infrastructure::fs::validation::PathValidator;
use crate::domain::ports::{CacheRepositoryPort, ConfigRepositoryPort, CategoryScannerPort};

/// The main outfit picker service.
///
/// This struct provides the high-level API for:
/// - Scanning categories
/// - Selecting random outfits
/// - Tracking worn outfits
/// - Managing rotation progress
pub struct OutfitPickerService<C, M, S> {
    config: Config,
    cache_manager: M,
    config_service: C,
    scanner: S,
}

/// Default OutfitPicker using concrete implementations.
pub type OutfitPicker = OutfitPickerService<ConfigService, CacheManager, CategoryScanner>;

impl OutfitPicker {
    /// Creates a new outfit picker with the given configuration.
    pub fn new(config: Config) -> Result<Self> {
        let cache_manager = CacheManager::new()?;
        let config_service = ConfigService::new()?;
        let scanner = CategoryScanner;

        Ok(Self {
            config,
            cache_manager,
            config_service,
            scanner,
        })
    }
}

impl<C, M, S> OutfitPickerService<C, M, S>
where
    C: ConfigRepositoryPort,
    M: CacheRepositoryPort,
    S: CategoryScannerPort,
{
    /// Creates an outfit picker with custom services (for testing).
    #[allow(dead_code)]
    pub fn with_services(
        config: Config,
        cache_manager: M,
        config_service: C,
        scanner: S,
    ) -> Self {
        Self {
            config,
            cache_manager,
            config_service,
            scanner,
        }
    }

    /// Gets the current configuration.
    pub fn config(&self) -> &Config {
        &self.config
    }

    /// Updates the configuration.
    pub async fn update_config(&mut self, config: Config) -> Result<()> {
        self.config_service.save(&config).await?;
        self.config = config;
        Ok(())
    }

    /// Changes the root path for outfit directories.
    ///
    /// This validates the new path and updates the configuration.
    /// Optionally clears the cache if the path is different.
    #[allow(dead_code)]
    pub async fn change_root_path(&mut self, new_path: impl AsRef<Path>, clear_cache: bool) -> Result<()> {
        let new_path = new_path.as_ref();

        // Validate the new path
        PathValidator::validate(new_path)?;

        // Check if the path is actually different
        let path_changed = self.config.root != new_path;

        if path_changed {
            // Update config with a new path
            let new_config = Config::new(new_path, self.config.language.clone())?;
            self.config_service.save(&new_config).await?;
            self.config = new_config;

            // Clear cache if requested (recommended when a path changes)
            if clear_cache {
                self.cache_manager.delete().await?;
            }
        }

        Ok(())
    }

    /// Gets the current root path.
    #[allow(dead_code)]
    pub fn root_path(&self) -> &Path {
        &self.config.root
    }

    /// Gets the current language.
    #[allow(dead_code)]
    pub fn language(&self) -> Option<&str> {
        self.config.language.as_deref()
    }

    /// Changes the language setting.
    ///
    /// Validates that the language is supported before changing.
    #[allow(dead_code)]
    pub async fn change_language(&mut self, language: Option<String>) -> Result<()> {
        // Validate language if provided
        if let Some(ref lang) = language {
            if !Config::is_supported_language(lang) {
                return Err(crate::domain::error::ConfigError::UnsupportedLanguage(lang.clone()).into());
            }
        }

        self.config.language = language;
        self.config_service.save(&self.config).await?;
        Ok(())
    }

    /// Gets the excluded categories.
    #[allow(dead_code)]
    pub fn excluded_categories(&self) -> &std::collections::HashSet<String> {
        &self.config.excluded_categories
    }

    /// Excludes a category from outfit selection.
    #[allow(dead_code)]
    pub async fn exclude_category(&mut self, category_name: &str) -> Result<()> {
        if category_name.trim().is_empty() {
            return Err(OutfitPickerError::InvalidInput(
                "Category name cannot be empty".to_string(),
            ));
        }

        self.config.excluded_categories.insert(category_name.to_string());
        self.config_service.save(&self.config).await?;
        Ok(())
    }

    /// Includes a previously excluded category.
    #[allow(dead_code)]
    pub async fn include_category(&mut self, category_name: &str) -> Result<()> {
        self.config.excluded_categories.remove(category_name);
        self.config_service.save(&self.config).await?;
        Ok(())
    }

    /// Gets rotation status for a category (worn count, total count).
    pub async fn get_rotation_status(&self, category_name: &str) -> Result<(usize, usize)> {
        let outfits = self.get_outfits(category_name).await?;
        let total = outfits.len();

        if total == 0 {
            return Ok((0, 0));
        }

        let category_path = outfits[0].category_path.to_string_lossy().to_string();
        let cache = self.cache_manager.load().await?;

        let worn = cache
            .categories
            .get(&category_path)
            .map(|c| c.worn_outfits.len())
            .unwrap_or(0);

        Ok((worn, total))
    }

    /// Checks if a category rotation is complete.
    pub async fn is_rotation_complete(&self, category_name: &str) -> Result<bool> {
        let (worn, total) = self.get_rotation_status(category_name).await?;
        Ok(total > 0 && worn >= total)
    }

    /// Helper to get the set of worn outfits for a category.
    async fn get_category_worn_set(&self, category_path: &str) -> Result<std::collections::HashSet<String>> {
        let cache = self.cache_manager.load().await?;
        Ok(cache
            .categories
            .get(category_path)
            .map(|c| c.worn_outfits.clone())
            .unwrap_or_default())
    }

    /// Scans for available categories with worn counts from the cache.
    pub async fn get_categories(&self) -> Result<Vec<CategoryInfo>> {
        let mut categories = self.scanner.scan_categories(&self.config.root, &self.config.excluded_categories).await?;
        
        // Load cache to get worn counts
        let cache = self.cache_manager.load().await.unwrap_or_default();
        
        // Populate worn counts from a cache
        for category in &mut categories {
            let path = category.category.path.to_string_lossy().to_string();
            if let Some(cat_cache) = cache.categories.get(&path) {
                category.worn_count = cat_cache.worn_outfits.len();
            }
        }
        
        Ok(categories)
    }

    /// Gets all outfits in a category.
    pub async fn get_outfits(&self, category_name: &str) -> Result<Vec<FileEntry>> {
        let categories = self.get_categories().await?;

        let category = categories
            .iter()
            .find(|c| c.category.name == category_name)
            .ok_or_else(|| OutfitPickerError::CategoryNotFound(category_name.to_string()))?;

        CategoryScanner::scan_outfits(&category.category.path).await
    }

    /// Selects a random outfit from a category.
    ///
    /// Returns None if no outfits are available.
    pub async fn select_random_outfit(
        &self,
        category_name: &str,
    ) -> Result<Option<OutfitSelection>> {
        // Validate category name
        if category_name.trim().is_empty() {
            return Err(OutfitPickerError::InvalidInput(
                "Category name cannot be empty".to_string(),
            ));
        }

        // Get all outfits in the category
        let outfits = self.get_outfits(category_name).await?;

        if outfits.is_empty() {
            return Ok(None);
        }

        // Load current cache
        let mut cache = self.cache_manager.load().await?;
        let category_path = outfits[0].category_path.to_string_lossy().to_string();

        // Get or create a category cache
        let category_cache = cache.get_or_create(&category_path, outfits.len());

        // Check if rotation is complete
        let mut rotation_was_reset = false;
        if category_cache.is_rotation_complete() {
            category_cache.reset();
            rotation_was_reset = true;
        }

        // Filter to unworn outfits
        let available: Vec<&FileEntry> = outfits
            .iter()
            .filter(|o| !category_cache.worn_outfits.contains(&o.file_name))
            .collect();

        // Select a random outfit
        let selected = available.choose(&mut rand::thread_rng());

        match selected {
            Some(outfit) => {
                let outfit = (*outfit).clone();

                // Mark as worn
                let category_cache = cache.get_or_create(&category_path, outfits.len());
                category_cache.add_worn(&outfit.file_name);

                let rotation_progress = category_cache.rotation_progress();

                // Save cache
                self.cache_manager.save(&cache).await?;

                Ok(Some(OutfitSelection::new(
                    outfit,
                    rotation_progress,
                    rotation_was_reset,
                )))
            }
            None => Ok(None),
        }
    }

    /// Selects a random outfit from any available category.
    pub async fn select_random_outfit_across_categories(&self) -> Result<Option<OutfitSelection>> {
        let categories = self.get_categories().await?;

        // Filter to categorise with outfits
        let available: Vec<&CategoryInfo> = categories
            .iter()
            .filter(|c| c.state == CategoryState::HasOutfits)
            .collect();

        if available.is_empty() {
            return Ok(None);
        }

        // Select a random category
        let category = available.choose(&mut rand::thread_rng());

        match category {
            Some(cat) => self.select_random_outfit(&cat.category.name).await,
            None => Ok(None),
        }
    }

    /// Marks an outfit as worn.
    pub async fn wear_outfit(&self, category_name: &str, file_name: &str) -> Result<()> {
        // Validate inputs
        if category_name.trim().is_empty() {
            return Err(OutfitPickerError::InvalidInput(
                "Category name cannot be empty".to_string(),
            ));
        }
        if file_name.trim().is_empty() {
            return Err(OutfitPickerError::InvalidInput(
                "File name cannot be empty".to_string(),
            ));
        }

        // Get outfits to find the category path
        let outfits = self.get_outfits(category_name).await?;

        if outfits.is_empty() {
            return Err(OutfitPickerError::NoOutfitsAvailable);
        }

        // Verify the outfit exists
        if !outfits.iter().any(|o| o.file_name == file_name) {
            return Err(OutfitPickerError::NoOutfitsAvailable);
        }

        let category_path = outfits[0].category_path.to_string_lossy().to_string();

        // Load and update cache
        let mut cache = self.cache_manager.load().await?;
        let category_cache = cache.get_or_create(&category_path, outfits.len());
        category_cache.add_worn(file_name);

        // Save cache
        self.cache_manager.save(&cache).await?;

        Ok(())
    }

    /// Resets the rotation for a specific category.
    pub async fn reset_category(&self, category_name: &str) -> Result<()> {
        let outfits = self.get_outfits(category_name).await?;

        if outfits.is_empty() {
            return Ok(());
        }

        let category_path = outfits[0].category_path.to_string_lossy().to_string();

        let mut cache = self.cache_manager.load().await?;

        if let Some(category_cache) = cache.categories.get_mut(&category_path) {
            category_cache.reset();
            self.cache_manager.save(&cache).await?;
        }

        Ok(())
    }

    /// Resets all category rotations.
    pub async fn reset_all_categories(&self) -> Result<()> {
        let mut cache = self.cache_manager.load().await?;
        cache.reset_all();
        self.cache_manager.save(&cache).await?;
        Ok(())
    }

    /// Performs a factory reset (deletes cache and config).
    pub async fn factory_reset(&self) -> Result<()> {
        self.cache_manager.delete().await?;
        self.config_service.delete().await?;
        Ok(())
    }

    /// Gets the worn outfits for all categories.
    pub async fn get_all_worn_outfits(&self) -> Result<Vec<(String, Vec<String>)>> {
        let cache = self.cache_manager.load().await?;

        let mut result: Vec<(String, Vec<String>)> = cache
            .categories
            .iter()
            .filter(|(_, c)| !c.worn_outfits.is_empty())
            .map(|(path, c)| {
                let mut worn: Vec<String> = c.worn_outfits.iter().cloned().collect();
                worn.sort();
                (path.clone(), worn)
            })
            .collect();

        result.sort_by(|a, b| a.0.cmp(&b.0));
        Ok(result)
    }

    /// Checks if an outfit is worn.
    pub async fn is_outfit_worn(&self, category_name: &str, file_name: &str) -> Result<bool> {
        let outfits = self.get_outfits(category_name).await?;

        if outfits.is_empty() {
            return Ok(false);
        }

        let category_path = outfits[0].category_path.to_string_lossy().to_string();
        let worn_set = self.get_category_worn_set(&category_path).await?;

        Ok(worn_set.contains(file_name))
    }

    /// Manually selects a specific outfit by name.
    ///
    /// This allows the user to choose a specific outfit rather than getting
    /// a random selection. The outfit is marked as worn in the rotation.
    ///
    /// Returns the OutfitSelection with rotation progress info or an error
    /// if the outfit doesn't exist.
    #[allow(dead_code)]
    pub async fn select_outfit_manually(
        &self,
        category_name: &str,
        file_name: &str,
    ) -> Result<OutfitSelection> {
        // Validate inputs
        if category_name.trim().is_empty() {
            return Err(OutfitPickerError::InvalidInput(
                "Category name cannot be empty".to_string(),
            ));
        }
        if file_name.trim().is_empty() {
            return Err(OutfitPickerError::InvalidInput(
                "File name cannot be empty".to_string(),
            ));
        }

        // Get all outfits in the category
        let outfits = self.get_outfits(category_name).await?;

        if outfits.is_empty() {
            return Err(OutfitPickerError::NoOutfitsAvailable);
        }

        // Find the specific outfit
        let outfit = outfits
            .iter()
            .find(|o| o.file_name == file_name)
            .ok_or_else(|| {
                OutfitPickerError::InvalidInput(format!(
                    "Outfit '{}' not found in category '{}'",
                    file_name, category_name
                ))
            })?
            .clone();

        let category_path = outfit.category_path.to_string_lossy().to_string();

        // Load current cache
        let mut cache = self.cache_manager.load().await?;

        // Get or create a category cache
        let category_cache = cache.get_or_create(&category_path, outfits.len());

        // Check if rotation is complete and reset if needed
        let mut rotation_was_reset = false;
        if category_cache.is_rotation_complete() {
            category_cache.reset();
            rotation_was_reset = true;
        }

        // Mark as worn
        category_cache.add_worn(&outfit.file_name);

        let rotation_progress = category_cache.rotation_progress();

        // Save cache
        self.cache_manager.save(&cache).await?;

        Ok(OutfitSelection::new(outfit, rotation_progress, rotation_was_reset))
    }

    /// Gets unworn outfits in a category.
    ///
    /// Returns outfits that haven't been worn in the current rotation.
    pub async fn get_unworn_outfits(&self, category_name: &str) -> Result<Vec<FileEntry>> {
        let outfits = self.get_outfits(category_name).await?;

        if outfits.is_empty() {
            return Ok(Vec::new());
        }

        let category_path = outfits[0].category_path.to_string_lossy().to_string();
        let worn_set = self.get_category_worn_set(&category_path).await?;

        Ok(outfits
            .into_iter()
            .filter(|o| !worn_set.contains(&o.file_name))
            .collect())
    }

    /// Gets worn outfits in a category.
    ///
    /// Returns outfits that have been worn in the current rotation.
    pub async fn get_worn_outfits(&self, category_name: &str) -> Result<Vec<FileEntry>> {
        let outfits = self.get_outfits(category_name).await?;

        if outfits.is_empty() {
            return Ok(Vec::new());
        }

        let category_path = outfits[0].category_path.to_string_lossy().to_string();
        let worn_set = self.get_category_worn_set(&category_path).await?;

        Ok(outfits
            .into_iter()
            .filter(|o| worn_set.contains(&o.file_name))
            .collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::infrastructure::cache::CacheManager;
    use crate::infrastructure::config::ConfigService;
    use tempfile::TempDir;
    use tokio::fs;

    async fn setup_test_env() -> (TempDir, OutfitPicker) {
        let temp = TempDir::new().unwrap();
        let root = temp.path().to_path_buf();

        // Create test categories
        let cat1 = root.join("Category1");
        let cat2 = root.join("Category2");
        fs::create_dir_all(&cat1).await.unwrap();
        fs::create_dir_all(&cat2).await.unwrap();

        // Create test outfits
        fs::write(cat1.join("outfit1.avatar"), "").await.unwrap();
        fs::write(cat1.join("outfit2.avatar"), "").await.unwrap();
        fs::write(cat2.join("outfit3.avatar"), "").await.unwrap();

        let config = Config::new(&root, Some("en".to_string())).unwrap();

        // Use isolated cache and config paths
        let cache_path = root.join("cache.json");
        let config_path = root.join("config.json");
        let cache_manager = CacheManager::with_path(cache_path);
        let config_service = ConfigService::with_path(config_path);
        let scanner = CategoryScanner;

        let picker = OutfitPicker::with_services(config, cache_manager, config_service, scanner);
        (temp, picker)
    }

    #[tokio::test]
    async fn test_get_categories() {
        let (_temp, picker) = setup_test_env().await;

        let categories = picker.get_categories().await.unwrap();
        assert_eq!(categories.len(), 2);
    }

    #[tokio::test]
    async fn test_get_outfits() {
        let (_temp, picker) = setup_test_env().await;

        let outfits = picker.get_outfits("Category1").await.unwrap();
        assert_eq!(outfits.len(), 2);
    }

    #[tokio::test]
    async fn test_select_random_outfit() {
        let (_temp, picker) = setup_test_env().await;

        let selection = picker.select_random_outfit("Category1").await.unwrap();
        assert!(selection.is_some());
    }

    #[tokio::test]
    async fn test_select_outfit_manually() {
        let (_temp, picker) = setup_test_env().await;

        // Select a specific outfit
        let selection = picker
            .select_outfit_manually("Category1", "outfit1.avatar")
            .await
            .unwrap();

        assert_eq!(selection.outfit.file_name, "outfit1.avatar");
        assert_eq!(selection.outfit.category_name, "Category1");
        assert!(!selection.rotation_was_reset);

        // Verify it's marked as worn
        let is_worn = picker
            .is_outfit_worn("Category1", "outfit1.avatar")
            .await
            .unwrap();
        assert!(is_worn);
    }

    #[tokio::test]
    async fn test_select_outfit_manually_nonexistent() {
        let (_temp, picker) = setup_test_env().await;

        // Try to select a non-existent outfit
        let result = picker
            .select_outfit_manually("Category1", "nonexistent.avatar")
            .await;

        assert!(result.is_err());
        match result {
            Err(OutfitPickerError::InvalidInput(msg)) => {
                assert!(msg.contains("not found"));
            }
            _ => panic!("Expected InvalidInput error"),
        }
    }

    #[tokio::test]
    async fn test_select_outfit_manually_empty_category() {
        let (_temp, picker) = setup_test_env().await;

        // Try with an empty category name
        let result = picker.select_outfit_manually("", "outfit1.avatar").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_select_outfit_manually_empty_filename() {
        let (_temp, picker) = setup_test_env().await;

        // Try with an empty file name
        let result = picker.select_outfit_manually("Category1", "").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_select_outfit_manually_updates_rotation() {
        let (_temp, picker) = setup_test_env().await;

        // Select the first outfit
        let selection1 = picker
            .select_outfit_manually("Category1", "outfit1.avatar")
            .await
            .unwrap();
        assert!(selection1.rotation_progress > 0.0);
        assert!(selection1.rotation_progress < 1.0);

        // Select a second outfit
        let selection2 = picker
            .select_outfit_manually("Category1", "outfit2.avatar")
            .await
            .unwrap();
        assert!(selection2.rotation_progress > selection1.rotation_progress);
    }

    #[tokio::test]
    async fn test_select_outfit_manually_resets_rotation_when_complete() {
        let (_temp, picker) = setup_test_env().await;

        // Wear all outfits in category
        picker
            .select_outfit_manually("Category1", "outfit1.avatar")
            .await
            .unwrap();
        picker
            .select_outfit_manually("Category1", "outfit2.avatar")
            .await
            .unwrap();

        // The next selection should trigger rotation reset
        let selection = picker
            .select_outfit_manually("Category1", "outfit1.avatar")
            .await
            .unwrap();
        assert!(selection.rotation_was_reset);
    }

    #[tokio::test]
    async fn test_get_unworn_outfits() {
        let (_temp, picker) = setup_test_env().await;

        // Initially all unworn
        let unworn = picker.get_unworn_outfits("Category1").await.unwrap();
        assert_eq!(unworn.len(), 2);

        // Wear one outfit
        picker
            .select_outfit_manually("Category1", "outfit1.avatar")
            .await
            .unwrap();

        // Now only one unworn
        let unworn = picker.get_unworn_outfits("Category1").await.unwrap();
        assert_eq!(unworn.len(), 1);
        assert_eq!(unworn[0].file_name, "outfit2.avatar");
    }

    #[tokio::test]
    async fn test_get_worn_outfits() {
        let (_temp, picker) = setup_test_env().await;

        // Initially none worn
        let worn = picker.get_worn_outfits("Category1").await.unwrap();
        assert_eq!(worn.len(), 0);

        // Wear one outfit
        picker
            .select_outfit_manually("Category1", "outfit1.avatar")
            .await
            .unwrap();

        // Now one worn
        let worn = picker.get_worn_outfits("Category1").await.unwrap();
        assert_eq!(worn.len(), 1);
        assert_eq!(worn[0].file_name, "outfit1.avatar");
    }

    #[tokio::test]
    async fn test_get_unworn_outfits_empty_category() {
        let temp = TempDir::new().unwrap();
        let root = temp.path().to_path_buf();
        let empty_cat = root.join("EmptyCategory");
        tokio::fs::create_dir_all(&empty_cat).await.unwrap();

        let config = Config::new(&root, Some("en".to_string())).unwrap();
        let cache_manager = CacheManager::with_path(root.join("cache.json"));
        let config_service = ConfigService::with_path(root.join("config.json"));
        let scanner = CategoryScanner;
        let picker = OutfitPicker::with_services(config, cache_manager, config_service, scanner);

        let unworn = picker.get_unworn_outfits("EmptyCategory").await.unwrap();
        assert_eq!(unworn.len(), 0);
    }

    #[tokio::test]
    async fn test_select_random_outfit_from_specific_category() {
        let (_temp, picker) = setup_test_env().await;

        // Pick random from Category1
        let selection = picker.select_random_outfit("Category1").await.unwrap();
        assert!(selection.is_some());
        let selection = selection.unwrap();

        // Verify it's from the correct category
        assert_eq!(selection.outfit.category_name, "Category1");
        assert!(
            selection.outfit.file_name == "outfit1.avatar"
                || selection.outfit.file_name == "outfit2.avatar"
        );
    }

    #[tokio::test]
    async fn test_select_random_outfit_marks_as_worn() {
        let (_temp, picker) = setup_test_env().await;

        // Pick a random outfit
        let selection = picker.select_random_outfit("Category1").await.unwrap();
        assert!(selection.is_some());
        let selection = selection.unwrap();

        // Verify it's now marked as worn
        let is_worn = picker
            .is_outfit_worn("Category1", &selection.outfit.file_name)
            .await
            .unwrap();
        assert!(is_worn);
    }

    #[tokio::test]
    async fn test_select_random_outfit_rotation_progress() {
        let (_temp, picker) = setup_test_env().await;

        // First pick
        let selection1 = picker.select_random_outfit("Category1").await.unwrap().unwrap();
        assert!(selection1.rotation_progress > 0.0);
        assert!(selection1.rotation_progress <= 1.0);
        assert!(!selection1.rotation_was_reset);

        // Second pick (should complete rotation for 2 outfits)
        let selection2 = picker.select_random_outfit("Category1").await.unwrap().unwrap();
        assert!(selection2.rotation_progress >= selection1.rotation_progress);
    }

    #[tokio::test]
    async fn test_select_random_outfit_resets_when_all_worn() {
        let (_temp, picker) = setup_test_env().await;

        // Wear all outfits in Category1 (has 2 outfits)
        picker.select_random_outfit("Category1").await.unwrap();
        picker.select_random_outfit("Category1").await.unwrap();

        // The third pick should trigger rotation reset
        let selection = picker.select_random_outfit("Category1").await.unwrap().unwrap();
        assert!(selection.rotation_was_reset);
    }

    #[tokio::test]
    async fn test_select_random_outfit_empty_category_name() {
        let (_temp, picker) = setup_test_env().await;

        let result = picker.select_random_outfit("").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_select_random_outfit_nonexistent_category() {
        let (_temp, picker) = setup_test_env().await;

        let result = picker.select_random_outfit("NonExistent").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_select_random_across_categories() {
        let (_temp, picker) = setup_test_env().await;

        // Pick random from any category
        let selection = picker.select_random_outfit_across_categories().await.unwrap();
        assert!(selection.is_some());
        let selection = selection.unwrap();

        // Verify it's from one of our categories
        assert!(
            selection.outfit.category_name == "Category1"
                || selection.outfit.category_name == "Category2"
        );
    }

    #[tokio::test]
    async fn test_change_root_path() {
        let (temp, mut picker) = setup_test_env().await;

        // Create a new directory with different outfits
        let new_root = temp.path().join("new_outfits");
        let new_cat = new_root.join("NewCategory");
        fs::create_dir_all(&new_cat).await.unwrap();
        fs::write(new_cat.join("new_outfit.avatar"), "").await.unwrap();

        // Change the root path
        picker.change_root_path(&new_root, false).await.unwrap();

        // Verify the path changed
        assert_eq!(picker.root_path(), new_root);

        // Verify we can see the new categories
        let categories = picker.get_categories().await.unwrap();
        assert_eq!(categories.len(), 1);
        assert_eq!(categories[0].category.name, "NewCategory");
    }

    #[tokio::test]
    async fn test_change_root_path_clears_cache() {
        let (temp, mut picker) = setup_test_env().await;

        // Wear an outfit to populate the cache
        picker.select_random_outfit("Category1").await.unwrap();

        // Create a new directory
        let new_root = temp.path().join("new_outfits");
        let new_cat = new_root.join("NewCategory");
        fs::create_dir_all(&new_cat).await.unwrap();
        fs::write(new_cat.join("new_outfit.avatar"), "").await.unwrap();

        // Change path with cache clear
        picker.change_root_path(&new_root, true).await.unwrap();

        // Path should be updated
        assert_eq!(picker.root_path(), new_root);
    }

    #[tokio::test]
    async fn test_change_root_path_same_path_no_op() {
        let (_temp, mut picker) = setup_test_env().await;

        let original_path = picker.root_path().to_path_buf();

        // Change to the same path
        picker.change_root_path(&original_path, false).await.unwrap();

        // Path should still be the same
        assert_eq!(picker.root_path(), original_path);
    }

    #[tokio::test]
    async fn test_change_root_path_invalid_path() {
        let (_temp, mut picker) = setup_test_env().await;

        // Try to change to an invalid path (path traversal)
        let result = picker.change_root_path("../../../etc", false).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_change_root_path_empty_path() {
        let (_temp, mut picker) = setup_test_env().await;

        // Try to change to an empty path
        let result = picker.change_root_path("", false).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_root_path_getter() {
        let (_temp, picker) = setup_test_env().await;

        // root_path should return the current path
        let path = picker.root_path();
        assert!(path.exists());
    }

    // === Language tests ===

    #[tokio::test]
    async fn test_change_language() {
        let (_temp, mut picker) = setup_test_env().await;

        // Change to Spanish
        picker.change_language(Some("es".to_string())).await.unwrap();
        assert_eq!(picker.language(), Some("es"));

        // Change to French
        picker.change_language(Some("fr".to_string())).await.unwrap();
        assert_eq!(picker.language(), Some("fr"));
    }

    #[tokio::test]
    async fn test_change_language_to_none() {
        let (_temp, mut picker) = setup_test_env().await;

        // Set a language first
        picker.change_language(Some("es".to_string())).await.unwrap();
        assert_eq!(picker.language(), Some("es"));

        // Clear the language
        picker.change_language(None).await.unwrap();
        assert_eq!(picker.language(), None);
    }

    #[tokio::test]
    async fn test_change_language_invalid() {
        let (_temp, mut picker) = setup_test_env().await;

        // Try an invalid language code
        let result = picker.change_language(Some("xyz".to_string())).await;
        assert!(result.is_err());
    }

    // === Excluded categories tests ===

    #[tokio::test]
    async fn test_exclude_category() {
        let (_temp, mut picker) = setup_test_env().await;

        // Exclude a category
        picker.exclude_category("Category1").await.unwrap();

        let excluded = picker.excluded_categories();
        assert!(excluded.contains("Category1"));
    }

    #[tokio::test]
    async fn test_include_category() {
        let (_temp, mut picker) = setup_test_env().await;

        // Exclude then include
        picker.exclude_category("Category1").await.unwrap();
        picker.include_category("Category1").await.unwrap();

        let excluded = picker.excluded_categories();
        assert!(!excluded.contains("Category1"));
    }

    #[tokio::test]
    async fn test_exclude_category_empty_name() {
        let (_temp, mut picker) = setup_test_env().await;

        let result = picker.exclude_category("").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_excluded_categories_filter_scan() {
        let (_temp, mut picker) = setup_test_env().await;

        // Exclude Category1
        picker.exclude_category("Category1").await.unwrap();

        // Get categories - Category1 should be marked as UserExcluded
        let categories = picker.get_categories().await.unwrap();
        assert_eq!(categories.len(), 2);
        
        let cat1 = categories.iter().find(|c| c.category.name == "Category1").unwrap();
        assert_eq!(cat1.state, CategoryState::UserExcluded);
        
        let cat2 = categories.iter().find(|c| c.category.name == "Category2").unwrap();
        assert_eq!(cat2.state, CategoryState::HasOutfits);
    }

    // === Rotation status tests ===

    #[tokio::test]
    async fn test_get_rotation_status() {
        let (_temp, picker) = setup_test_env().await;

        // Initially no outfits worn
        let (worn, total) = picker.get_rotation_status("Category1").await.unwrap();
        assert_eq!(worn, 0);
        assert_eq!(total, 2);
    }

    #[tokio::test]
    async fn test_get_rotation_status_after_wearing() {
        let (_temp, picker) = setup_test_env().await;

        // Wear one outfit
        picker.select_random_outfit("Category1").await.unwrap();

        let (worn, total) = picker.get_rotation_status("Category1").await.unwrap();
        assert_eq!(worn, 1);
        assert_eq!(total, 2);
    }

    #[tokio::test]
    async fn test_is_rotation_complete() {
        let (_temp, picker) = setup_test_env().await;

        // Initially not complete
        assert!(!picker.is_rotation_complete("Category1").await.unwrap());

        // Wear all outfits
        picker.select_random_outfit("Category1").await.unwrap();
        picker.select_random_outfit("Category1").await.unwrap();

        // Now complete
        assert!(picker.is_rotation_complete("Category1").await.unwrap());
    }

    #[tokio::test]
    async fn test_scan_categories_failure() {
        let temp = TempDir::new().unwrap();
        let root = temp.path().to_path_buf();
        let config = Config::new(&root, Some("en".to_string())).unwrap();
        
        // Mocks
        let cache_manager = CacheManager::with_path(root.join("cache.json"));
        let config_service = ConfigService::with_path(root.join("config.json"));
        
        struct FailingScanner;
        #[async_trait::async_trait]
        impl CategoryScannerPort for FailingScanner {
            async fn scan_categories(&self, _root: &Path, _excluded: &std::collections::HashSet<String>) -> Result<Vec<CategoryInfo>> {
                Err(OutfitPickerError::FileSystem(crate::domain::error::FileSystemError::OperationFailed("Mock failure".into())))
            }
        }
        
        let picker = OutfitPickerService::with_services(config, cache_manager, config_service, FailingScanner);
        
        let result = picker.get_categories().await;
        assert!(result.is_err());
        match result.unwrap_err() {
            OutfitPickerError::FileSystem(crate::domain::error::FileSystemError::OperationFailed(msg)) => {
                assert_eq!(msg, "Mock failure");
            }
            _ => panic!("Wrong error type"),
        }
    }

    #[tokio::test]
    async fn test_cache_load_failure() {
        let temp = TempDir::new().unwrap();
        let root = temp.path().to_path_buf();
        let config = Config::new(&root, Some("en".to_string())).unwrap();
        
        // Mocks
        let config_service = ConfigService::with_path(root.join("config.json"));
        let scanner = CategoryScanner;
        
        #[derive(Clone)]
        struct FailingCacheManager;
        #[async_trait::async_trait]
        impl CacheRepositoryPort for FailingCacheManager {
            async fn load(&self) -> Result<crate::domain::models::OutfitCache> {
                Err(OutfitPickerError::Cache(crate::domain::error::CacheError::DecodingFailed))
            }
            async fn save(&self, _cache: &crate::domain::models::OutfitCache) -> Result<()> { Ok(()) }
            async fn delete(&self) -> Result<()> { Ok(()) }
        }
        
        let picker = OutfitPickerService::with_services(config, FailingCacheManager, config_service, scanner);
        
        // get_all_worn_outfits calls cache.load() immediately
        let result = picker.get_all_worn_outfits().await;
        assert!(result.is_err());
        match result.unwrap_err() {
            OutfitPickerError::Cache(crate::domain::error::CacheError::DecodingFailed) => {},
            _ => panic!("Wrong error type"),
        }
    }

    #[tokio::test]
    async fn test_factory_reset() {
        let (temp, picker) = setup_test_env().await;

        // Wear an outfit to create a cache
        picker.select_random_outfit("Category1").await.unwrap();
        
        // Save config
        let config = picker.config().clone();
        picker.config_service.save(&config).await.unwrap();
        
        assert!(temp.path().join("cache.json").exists() || temp.path().join("config.json").exists());
        
        // Factory reset
        picker.factory_reset().await.unwrap();
        
        // Files should be deleted
        assert!(!temp.path().join("cache.json").exists());
        assert!(!temp.path().join("config.json").exists());
    }

    #[tokio::test]
    async fn test_update_config() {
        let (_temp, mut picker) = setup_test_env().await;

        let original_language = picker.config().language.clone();
        
        // Update config with a new language
        let mut new_config = picker.config().clone();
        new_config.language = Some("es".to_string());
        
        picker.update_config(new_config.clone()).await.unwrap();
        
        // Verify config is updated
        assert_eq!(picker.config().language, Some("es".to_string()));
        assert_ne!(picker.config().language, original_language);
    }

    #[tokio::test]
    async fn test_config_getter() {
        let (_temp, picker) = setup_test_env().await;

        let config = picker.config();
        assert!(config.root.exists());
        assert_eq!(config.language, Some("en".to_string()));
    }

    #[tokio::test]
    async fn test_get_all_worn_outfits() {
        let (_temp, picker) = setup_test_env().await;

        // Initially empty
        let worn = picker.get_all_worn_outfits().await.unwrap();
        assert!(worn.is_empty());

        // Wear some outfits
        picker.select_outfit_manually("Category1", "outfit1.avatar").await.unwrap();
        picker.select_outfit_manually("Category2", "outfit3.avatar").await.unwrap();

        // Now should have worn outfits
        let worn = picker.get_all_worn_outfits().await.unwrap();
        assert_eq!(worn.len(), 2);
    }

    #[tokio::test]
    async fn test_get_rotation_status_empty_category() {
        let temp = TempDir::new().unwrap();
        let root = temp.path().to_path_buf();
        let empty_cat = root.join("EmptyCategory");
        fs::create_dir_all(&empty_cat).await.unwrap();

        let config = Config::new(&root, Some("en".to_string())).unwrap();
        let cache_manager = CacheManager::with_path(root.join("cache.json"));
        let config_service = ConfigService::with_path(root.join("config.json"));
        let scanner = CategoryScanner;
        let picker = OutfitPicker::with_services(config, cache_manager, config_service, scanner);

        let (worn, total) = picker.get_rotation_status("EmptyCategory").await.unwrap();
        assert_eq!(worn, 0);
        assert_eq!(total, 0);
    }
}
