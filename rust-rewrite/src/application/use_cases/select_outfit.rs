//! Use case for selecting outfits.
//!
//! This module contains the business logic for selecting random outfits
//! from categories, including rotation tracking.

use rand::seq::SliceRandom;
use crate::domain::error::{OutfitPickerError, Result};
use crate::domain::models::{CategoryInfo, CategoryState, FileEntry, OutfitSelection};
use crate::domain::ports::{CacheRepositoryPort, CategoryScannerPort};
use std::collections::HashSet;
use std::path::Path;

/// Use case for selecting a random outfit from a category.
pub struct SelectOutfitUseCase<'a, M, S> {
    cache_repository: &'a M,
    scanner: &'a S,
}

impl<'a, M, S> SelectOutfitUseCase<'a, M, S>
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

    /// Selects a random outfit from the specified category.
    pub async fn execute(
        &self,
        root: &Path,
        excluded_categories: &HashSet<String>,
        category_name: &str,
    ) -> Result<Option<OutfitSelection>> {
        // Validate category name
        if category_name.trim().is_empty() {
            return Err(OutfitPickerError::InvalidInput(
                "Category name cannot be empty".to_string(),
            ));
        }

        // Get all categories to find the one we want
        let categories = self.scanner.scan_categories(root, excluded_categories).await?;
        
        let category = categories
            .iter()
            .find(|c| c.category.name == category_name)
            .ok_or_else(|| OutfitPickerError::CategoryNotFound(category_name.to_string()))?;

        // Get outfits in the category
        let outfits = crate::infrastructure::fs::scanner::CategoryScanner::scan_outfits(&category.category.path).await?;

        if outfits.is_empty() {
            return Ok(None);
        }

        // Load current cache
        let mut cache = self.cache_repository.load().await?;
        let category_path = outfits[0].category_path.to_string_lossy().to_string();

        // Get or create category cache
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

        // Select random outfit
        let selected = available.choose(&mut rand::thread_rng());

        match selected {
            Some(outfit) => {
                let outfit = (*outfit).clone();

                // Mark as worn
                let category_cache = cache.get_or_create(&category_path, outfits.len());
                category_cache.add_worn(&outfit.file_name);

                let rotation_progress = category_cache.rotation_progress();

                // Save cache
                self.cache_repository.save(&cache).await?;

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
    pub async fn execute_across_categories(
        &self,
        root: &Path,
        excluded_categories: &HashSet<String>,
    ) -> Result<Option<OutfitSelection>> {
        let categories = self.scanner.scan_categories(root, excluded_categories).await?;

        // Filter to categories with outfits
        let available: Vec<&CategoryInfo> = categories
            .iter()
            .filter(|c| c.state == CategoryState::HasOutfits)
            .collect();

        if available.is_empty() {
            return Ok(None);
        }

        // Select random category
        let category = available.choose(&mut rand::thread_rng());

        match category {
            Some(cat) => self.execute(root, excluded_categories, &cat.category.name).await,
            None => Ok(None),
        }
    }
}
