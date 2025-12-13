//! Category scanning and file system operations.
//!
//! This module handles scanning the file system for categories and outfits,
//! providing async concurrent scanning for performance.

use std::path::Path;
use tokio::fs;
use async_trait::async_trait;
use futures::stream::{self, StreamExt};
use crate::domain::error::{FileSystemError, Result};
use crate::domain::models::{CategoryInfo, CategoryReference, CategoryState, FileEntry};
use crate::domain::ports::CategoryScannerPort;

/// The file extension for avatar/outfit files.
#[allow(dead_code)]
pub const OUTFIT_EXTENSION: &str = ".avatar";

/// Maximum number of concurrent category scans.
const MAX_CONCURRENT_SCANS: usize = 10;

/// Scans the file system for categories and outfits.
#[derive(Clone, Default)]
pub struct CategoryScanner;

#[async_trait]
impl CategoryScannerPort for CategoryScanner {
    async fn scan_categories(
        &self,
        root: &Path,
        excluded_categories: &std::collections::HashSet<String>,
    ) -> Result<Vec<CategoryInfo>> {
        Self::scan_categories(root, excluded_categories).await
    }
}

impl CategoryScanner {
    /// Scans for categories in the given root directory.
    ///
    /// Uses concurrent scanning for better performance with many categories.
    /// Returns a list of CategoryInfo for each subdirectory found.
    pub async fn scan_categories(
        root: &Path,
        excluded_categories: &std::collections::HashSet<String>,
    ) -> Result<Vec<CategoryInfo>> {
        // Verify root exists
        if !root.exists() {
            return Err(FileSystemError::DirectoryNotFound(
                root.to_string_lossy().to_string(),
            )
            .into());
        }

        // Collect all directory entries first
        let mut dir_entries = Vec::new();
        let mut entries = fs::read_dir(root).await.map_err(|e| {
            FileSystemError::OperationFailed(format!("Failed to read directory: {}", e))
        })?;

        while let Some(entry) = entries.next_entry().await.map_err(|e| {
            FileSystemError::OperationFailed(format!("Failed to read entry: {}", e))
        })? {
            let path = entry.path();

            // Only process directories
            if !path.is_dir() {
                continue;
            }

            let name = path
                .file_name()
                .map(|s| s.to_string_lossy().to_string())
                .unwrap_or_default();

            // Skip hidden directories
            if name.starts_with('.') {
                continue;
            }

            dir_entries.push((name, path));
        }

        // Process directories concurrently
        let excluded = excluded_categories.clone();
        let categories: Vec<Result<CategoryInfo>> = stream::iter(dir_entries)
            .map(|(name, path)| {
                let excluded = excluded.clone();
                async move {
                    Self::scan_single_category(name, path, &excluded).await
                }
            })
            .buffer_unordered(MAX_CONCURRENT_SCANS)
            .collect()
            .await;

        // Collect results, propagating errors
        let mut result: Vec<CategoryInfo> = Vec::new();
        for cat_result in categories {
            result.push(cat_result?);
        }

        // Sort by name
        result.sort_by(|a, b| a.category.name.cmp(&b.category.name));

        Ok(result)
    }

    /// Scans a single category directory.
    async fn scan_single_category(
        name: String,
        path: std::path::PathBuf,
        excluded_categories: &std::collections::HashSet<String>,
    ) -> Result<CategoryInfo> {
        let category_ref = CategoryReference::new(&name, &path);

        // Check if excluded
        if excluded_categories.contains(&name) {
            return Ok(CategoryInfo::new(category_ref, CategoryState::UserExcluded, 0));
        }

        // Scan for outfit files
        let outfits = Self::scan_outfits(&path).await?;
        let outfit_count = outfits.len();

        let state = if outfit_count > 0 {
            CategoryState::HasOutfits
        } else {
            // Check if there are any files at all
            let has_files = Self::has_any_files(&path).await?;
            if has_files {
                CategoryState::NoAvatarFiles
            } else {
                CategoryState::Empty
            }
        };

        Ok(CategoryInfo::new(category_ref, state, outfit_count))
    }

    /// Scans for outfit files in a category directory.
    pub async fn scan_outfits(category_path: &Path) -> Result<Vec<FileEntry>> {
        let mut outfits = Vec::new();

        let mut entries = fs::read_dir(category_path).await.map_err(|e| {
            FileSystemError::OperationFailed(format!("Failed to read category: {}", e))
        })?;

        while let Some(entry) = entries.next_entry().await.map_err(|e| {
            FileSystemError::OperationFailed(format!("Failed to read entry: {}", e))
        })? {
            let path = entry.path();

            // Only process files
            if !path.is_file() {
                continue;
            }

            let file_entry = FileEntry::new(&path);

            // Only include avatar files
            if file_entry.is_avatar_file() {
                outfits.push(file_entry);
            }
        }

        // Sort by file name
        outfits.sort_by(|a, b| a.file_name.cmp(&b.file_name));

        Ok(outfits)
    }

    /// Checks if a directory has any files (not just avatar files).
    async fn has_any_files(path: &Path) -> Result<bool> {
        let mut entries = fs::read_dir(path).await.map_err(|e| {
            FileSystemError::OperationFailed(format!("Failed to read directory: {}", e))
        })?;

        while let Some(entry) = entries.next_entry().await.map_err(|e| {
            FileSystemError::OperationFailed(format!("Failed to read entry: {}", e))
        })? {
            if entry.path().is_file() {
                return Ok(true);
            }
        }

        Ok(false)
    }

    /// Filters a list of file names to only include avatar files.
    #[allow(dead_code)]
    pub fn filter_avatar_files(files: &[String]) -> Vec<String> {
        files
            .iter()
            .filter(|f| f.ends_with(OUTFIT_EXTENSION))
            .cloned()
            .collect()
    }

    /// Checks if a file name is an avatar file.
    #[allow(dead_code)]
    pub fn is_avatar_file(file_name: &str) -> bool {
        file_name.ends_with(OUTFIT_EXTENSION)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    use tokio::fs;

    #[test]
    fn test_is_avatar_file() {
        assert!(CategoryScanner::is_avatar_file("outfit.avatar"));
        assert!(!CategoryScanner::is_avatar_file("readme.txt"));
        assert!(!CategoryScanner::is_avatar_file("outfit.png"));
    }

    #[test]
    fn test_is_avatar_file_case_sensitivity() {
        // File extensions are typically case-sensitive on Unix
        assert!(!CategoryScanner::is_avatar_file("outfit.AVATAR"));
        assert!(!CategoryScanner::is_avatar_file("outfit.Avatar"));
    }

    #[test]
    fn test_is_avatar_file_empty() {
        assert!(!CategoryScanner::is_avatar_file(""));
        // Note: ".avatar" technically ends with ".avatar" so it returns true
        // This is acceptable behavior - it's a hidden file with avatar extension
        assert!(CategoryScanner::is_avatar_file(".avatar"));
    }

    #[test]
    fn test_is_avatar_file_path_components() {
        // Should match extension, not path component
        assert!(!CategoryScanner::is_avatar_file("path/to/.avatar/file.txt"));
        assert!(CategoryScanner::is_avatar_file("path/to/outfit.avatar"));
    }

    #[test]
    fn test_filter_avatar_files() {
        let files = vec![
            "outfit1.avatar".to_string(),
            "readme.txt".to_string(),
            "outfit2.avatar".to_string(),
            "notes.md".to_string(),
        ];

        let filtered = CategoryScanner::filter_avatar_files(&files);
        assert_eq!(filtered.len(), 2);
        assert!(filtered.contains(&"outfit1.avatar".to_string()));
        assert!(filtered.contains(&"outfit2.avatar".to_string()));
    }

    #[test]
    fn test_filter_avatar_files_empty_list() {
        let files: Vec<String> = vec![];
        let filtered = CategoryScanner::filter_avatar_files(&files);
        assert!(filtered.is_empty());
    }

    #[test]
    fn test_filter_avatar_files_no_matches() {
        let files = vec![
            "readme.txt".to_string(),
            "notes.md".to_string(),
            "image.png".to_string(),
        ];

        let filtered = CategoryScanner::filter_avatar_files(&files);
        assert!(filtered.is_empty());
    }

    #[test]
    fn test_filter_avatar_files_all_matches() {
        let files = vec![
            "outfit1.avatar".to_string(),
            "outfit2.avatar".to_string(),
        ];

        let filtered = CategoryScanner::filter_avatar_files(&files);
        assert_eq!(filtered.len(), 2);
    }

    #[tokio::test]
    async fn test_scan_categories_nonexistent_directory() {
        let result = CategoryScanner::scan_categories(
            Path::new("/nonexistent/path/that/does/not/exist"),
            &std::collections::HashSet::new(),
        ).await;

        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_scan_outfits_nonexistent_directory() {
        let result = CategoryScanner::scan_outfits(
            Path::new("/nonexistent/path/that/does/not/exist"),
        ).await;

        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_scan_categories_with_real_directories() {
        let temp = TempDir::new().unwrap();
        let root = temp.path();

        // Create test categories
        fs::create_dir_all(root.join("Category1")).await.unwrap();
        fs::create_dir_all(root.join("Category2")).await.unwrap();
        fs::write(root.join("Category1/outfit1.avatar"), "").await.unwrap();
        fs::write(root.join("Category2/outfit2.avatar"), "").await.unwrap();

        let result = CategoryScanner::scan_categories(
            root,
            &std::collections::HashSet::new(),
        ).await.unwrap();

        assert_eq!(result.len(), 2);
        // Results should be sorted by name
        assert_eq!(result[0].category.name, "Category1");
        assert_eq!(result[1].category.name, "Category2");
    }

    #[tokio::test]
    async fn test_scan_categories_skips_hidden_directories() {
        let temp = TempDir::new().unwrap();
        let root = temp.path();

        fs::create_dir_all(root.join("VisibleCategory")).await.unwrap();
        fs::create_dir_all(root.join(".HiddenCategory")).await.unwrap();
        fs::write(root.join("VisibleCategory/outfit.avatar"), "").await.unwrap();
        fs::write(root.join(".HiddenCategory/outfit.avatar"), "").await.unwrap();

        let result = CategoryScanner::scan_categories(
            root,
            &std::collections::HashSet::new(),
        ).await.unwrap();

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].category.name, "VisibleCategory");
    }

    #[tokio::test]
    async fn test_scan_categories_ignores_files_at_root() {
        let temp = TempDir::new().unwrap();
        let root = temp.path();

        fs::create_dir_all(root.join("Category1")).await.unwrap();
        fs::write(root.join("readme.txt"), "").await.unwrap();
        fs::write(root.join("Category1/outfit.avatar"), "").await.unwrap();

        let result = CategoryScanner::scan_categories(
            root,
            &std::collections::HashSet::new(),
        ).await.unwrap();

        // Should only have the directory, not the file
        assert_eq!(result.len(), 1);
        assert_eq!(result[0].category.name, "Category1");
    }

    #[tokio::test]
    async fn test_scan_outfits_returns_sorted() {
        let temp = TempDir::new().unwrap();
        let category = temp.path().join("Category");
        fs::create_dir_all(&category).await.unwrap();

        fs::write(category.join("zebra.avatar"), "").await.unwrap();
        fs::write(category.join("apple.avatar"), "").await.unwrap();
        fs::write(category.join("mango.avatar"), "").await.unwrap();

        let result = CategoryScanner::scan_outfits(&category).await.unwrap();

        assert_eq!(result.len(), 3);
        assert_eq!(result[0].file_name, "apple.avatar");
        assert_eq!(result[1].file_name, "mango.avatar");
        assert_eq!(result[2].file_name, "zebra.avatar");
    }

    #[tokio::test]
    async fn test_scan_outfits_ignores_non_avatar_files() {
        let temp = TempDir::new().unwrap();
        let category = temp.path().join("Category");
        fs::create_dir_all(&category).await.unwrap();

        fs::write(category.join("outfit.avatar"), "").await.unwrap();
        fs::write(category.join("readme.txt"), "").await.unwrap();
        fs::write(category.join("image.png"), "").await.unwrap();

        let result = CategoryScanner::scan_outfits(&category).await.unwrap();

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].file_name, "outfit.avatar");
    }

    #[tokio::test]
    async fn test_scan_categories_empty_category() {
        let temp = TempDir::new().unwrap();
        let root = temp.path();

        fs::create_dir_all(root.join("EmptyCategory")).await.unwrap();

        let result = CategoryScanner::scan_categories(
            root,
            &std::collections::HashSet::new(),
        ).await.unwrap();

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].state, CategoryState::Empty);
        assert_eq!(result[0].outfit_count, 0);
    }

    #[tokio::test]
    async fn test_scan_categories_no_avatar_files() {
        let temp = TempDir::new().unwrap();
        let root = temp.path();
        let category = root.join("NoAvatarCategory");

        fs::create_dir_all(&category).await.unwrap();
        fs::write(category.join("readme.txt"), "").await.unwrap();
        fs::write(category.join("notes.md"), "").await.unwrap();

        let result = CategoryScanner::scan_categories(
            root,
            &std::collections::HashSet::new(),
        ).await.unwrap();

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].state, CategoryState::NoAvatarFiles);
    }

    #[tokio::test]
    async fn test_scan_categories_with_exclusions() {
        let temp = TempDir::new().unwrap();
        let root = temp.path();

        fs::create_dir_all(root.join("Category1")).await.unwrap();
        fs::create_dir_all(root.join("Category2")).await.unwrap();
        fs::write(root.join("Category1/outfit.avatar"), "").await.unwrap();
        fs::write(root.join("Category2/outfit.avatar"), "").await.unwrap();

        let mut excluded = std::collections::HashSet::new();
        excluded.insert("Category1".to_string());

        let result = CategoryScanner::scan_categories(root, &excluded).await.unwrap();

        assert_eq!(result.len(), 2);
        let cat1 = result.iter().find(|c| c.category.name == "Category1").unwrap();
        assert_eq!(cat1.state, CategoryState::UserExcluded);

        let cat2 = result.iter().find(|c| c.category.name == "Category2").unwrap();
        assert_eq!(cat2.state, CategoryState::HasOutfits);
    }
}
