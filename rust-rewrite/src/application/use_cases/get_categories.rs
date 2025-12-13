//! Use case for getting categories.
//!
//! This module contains the business logic for scanning and retrieving
//! category information with worn counts.

use crate::domain::error::Result;
use crate::domain::models::CategoryInfo;
use crate::domain::ports::{CacheRepositoryPort, CategoryScannerPort};
use std::collections::HashSet;
use std::path::Path;

/// Use case for getting categories with their current state.
pub struct GetCategoriesUseCase<'a, M, S> {
    cache_repository: &'a M,
    scanner: &'a S,
}

impl<'a, M, S> GetCategoriesUseCase<'a, M, S>
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

    /// Scans for available categories with worn counts from cache.
    pub async fn execute(
        &self,
        root: &Path,
        excluded_categories: &HashSet<String>,
    ) -> Result<Vec<CategoryInfo>> {
        let mut categories = self.scanner.scan_categories(root, excluded_categories).await?;
        
        // Load cache to get worn counts
        let cache = self.cache_repository.load().await.unwrap_or_default();
        
        // Populate worn counts from cache
        for category in &mut categories {
            if let Some(cat_cache) = cache.categories.get(&category.category.name) {
                category.worn_count = cat_cache.worn_outfits.len();
            }
        }
        
        Ok(categories)
    }
}
