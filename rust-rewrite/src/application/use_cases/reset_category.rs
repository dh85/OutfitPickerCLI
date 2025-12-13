//! Use case for resetting category rotations.
//!
//! This module contains the business logic for resetting worn outfit
//! tracking in one or all categories.

use crate::domain::error::{OutfitPickerError, Result};
use crate::domain::models::FileEntry;
use crate::domain::ports::{CacheRepositoryPort, CategoryScannerPort};
use std::collections::HashSet;
use std::path::Path;

/// Use case for resetting category rotations.
pub struct ResetCategoryUseCase<'a, M, S> {
    cache_repository: &'a M,
    scanner: &'a S,
}

impl<'a, M, S> ResetCategoryUseCase<'a, M, S>
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

    /// Resets the rotation for a specific category.
    pub async fn execute(
        &self,
        root: &Path,
        excluded_categories: &HashSet<String>,
        category_name: &str,
    ) -> Result<()> {
        let outfits = self.get_outfits(root, excluded_categories, category_name).await?;

        if outfits.is_empty() {
            return Ok(());
        }

        let category_path = outfits[0].category_path.to_string_lossy().to_string();

        let mut cache = self.cache_repository.load().await?;

        if let Some(category_cache) = cache.categories.get_mut(&category_path) {
            category_cache.reset();
            self.cache_repository.save(&cache).await?;
        }

        Ok(())
    }

    /// Resets all category rotations.
    pub async fn execute_all(&self) -> Result<()> {
        let mut cache = self.cache_repository.load().await?;
        cache.reset_all();
        self.cache_repository.save(&cache).await?;
        Ok(())
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
