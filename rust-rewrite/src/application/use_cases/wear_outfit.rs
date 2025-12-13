//! Use case for wearing outfits.
//!
//! This module contains the business logic for marking outfits as worn
//! and tracking rotation progress.

use crate::domain::error::{OutfitPickerError, Result};
use crate::domain::models::{FileEntry, OutfitSelection};
use crate::domain::ports::{CacheRepositoryPort, CategoryScannerPort};
use std::collections::HashSet;
use std::path::Path;

/// Use case for marking an outfit as worn.
pub struct WearOutfitUseCase<'a, M, S> {
    cache_repository: &'a M,
    scanner: &'a S,
}

impl<'a, M, S> WearOutfitUseCase<'a, M, S>
where
    M: CacheRepositoryPort,
    S: CategoryScannerPort,
{
    pub fn new(cache_repository: &'a M, scanner: &'a S) -> Self {
        Self {
            cache_repository,
            scanner,
        }
    }

    /// Marks an outfit as worn without returning selection info.
    pub async fn execute(
        &self,
        root: &Path,
        excluded_categories: &HashSet<String>,
        category_name: &str,
        file_name: &str,
    ) -> Result<()> {
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
        let outfits = self.get_outfits(root, excluded_categories, category_name).await?;

        if outfits.is_empty() {
            return Err(OutfitPickerError::NoOutfitsAvailable);
        }

        // Verify the outfit exists
        if !outfits.iter().any(|o| o.file_name == file_name) {
            return Err(OutfitPickerError::NoOutfitsAvailable);
        }

        let category_path = outfits[0].category_path.to_string_lossy().to_string();

        // Load and update cache
        let mut cache = self.cache_repository.load().await?;
        let category_cache = cache.get_or_create(&category_path, outfits.len());
        category_cache.add_worn(file_name);

        // Save cache
        self.cache_repository.save(&cache).await?;

        Ok(())
    }

    /// Manually selects a specific outfit by name and returns selection info.
    pub async fn execute_with_selection(
        &self,
        root: &Path,
        excluded_categories: &HashSet<String>,
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
        let outfits = self.get_outfits(root, excluded_categories, category_name).await?;

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
        let mut cache = self.cache_repository.load().await?;

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
        self.cache_repository.save(&cache).await?;

        Ok(OutfitSelection::new(outfit, rotation_progress, rotation_was_reset))
    }

    async fn get_outfits(
        &self,
        root: &Path,
        excluded_categories: &HashSet<String>,
        category_name: &str,
    ) -> Result<Vec<FileEntry>> {
        let categories = self.scanner.scan_categories(root, excluded_categories).await?;

        let category = categories
            .iter()
            .find(|c| c.category.name == category_name)
            .ok_or_else(|| OutfitPickerError::CategoryNotFound(category_name.to_string()))?;

        crate::infrastructure::fs::scanner::CategoryScanner::scan_outfits(&category.category.path).await
    }
}
