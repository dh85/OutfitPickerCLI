//! Core data models for the outfit picker application.
//!
//! This module contains all the domain models including:
//! - Configuration
//! - Category information
//! - File entries
//! - Cache structures

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};

use crate::domain::error::{ConfigError, Result};
use crate::domain::validation::PathValidation;

/// Configuration for the outfit picker application.
///
/// Stores the root directory path for outfit files and optional language preference.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Config {
    /// Root directory path containing outfit files
    pub root: PathBuf,
    /// Language code for localization (e.g., "en", "es", "fr")
    pub language: Option<String>,
    /// Categories excluded from outfit selection
    #[serde(default)]
    pub excluded_categories: HashSet<String>,
    /// Categories discovered in the filesystem
    #[serde(default)]
    pub known_categories: HashSet<String>,
    /// Files tracked per category for change detection
    #[serde(default)]
    pub known_category_files: HashMap<String, HashSet<String>>,
}

impl Config {
    /// Creates and validates a new configuration.
    ///
    /// Performs comprehensive validation including:
    /// - Path security checks (traversal, restricted directories)
    /// - Language code validation
    pub fn new(root: impl AsRef<Path>, language: Option<String>) -> Result<Self> {
        let root = root.as_ref();

        // Validate the path
        PathValidation::validate(root)?;

        // Validate language if provided
        if let Some(ref lang) = language {
            if !Self::is_supported_language(lang) {
                return Err(ConfigError::UnsupportedLanguage(lang.clone()).into());
            }
        }

        Ok(Self {
            root: root.to_path_buf(),
            language,
            excluded_categories: HashSet::new(),
            known_categories: HashSet::new(),
            known_category_files: HashMap::new(),
        })
    }

    /// Creates a configuration with additional options.
    #[allow(dead_code)]
    pub fn with_exclusions(
        root: impl AsRef<Path>,
        language: Option<String>,
        excluded_categories: HashSet<String>,
    ) -> Result<Self> {
        let mut config = Self::new(root, language)?;
        config.excluded_categories = excluded_categories;
        Ok(config)
    }

    /// Returns the default language code.
    #[allow(dead_code)]
    pub fn default_language() -> &'static str {
        "en"
    }

    /// Checks if a language code is supported.
    pub fn is_supported_language(lang: &str) -> bool {
        SUPPORTED_LANGUAGES.contains(&lang)
    }

    /// Returns all supported language codes.
    #[allow(dead_code)]
    pub fn supported_languages() -> &'static [&'static str] {
        SUPPORTED_LANGUAGES
    }
}

/// Supported language codes (ISO 639-1).
const SUPPORTED_LANGUAGES: &[&str] = &[
    "en", "es", "fr", "de", "pt", "it", "nl", "ru", "ja", "zh",
    "ko", "ar", "hi", "sv", "fi", "no", "da", "pl", "hu", "hr",
    "sr", "ro", "el", "tr", "bg", "lt", "lv", "et", "is", "ca",
    "mt", "sk", "cs", "uk", "sl", "bn", "vi", "th", "he", "id",
    "ta", "ms", "te", "pa", "am", "ur", "gu", "sw", "zu", "af", "yo",
];

/// Represents the current state of a category directory.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum CategoryState {
    /// Category contains outfit files that can be used
    HasOutfits,
    /// Category directory exists but contains no files
    Empty,
    /// Category contains files but no .avatar files
    NoAvatarFiles,
    /// Category has been excluded by user configuration
    UserExcluded,
}

/// Reference to a category by name and path.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct CategoryReference {
    /// The name of the category (directory name)
    pub name: String,
    /// The full path to the category directory
    pub path: PathBuf,
}

impl CategoryReference {
    pub fn new(name: impl Into<String>, path: impl Into<PathBuf>) -> Self {
        Self {
            name: name.into(),
            path: path.into(),
        }
    }
}

/// Combines a category with its current state information.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CategoryInfo {
    /// Reference to the category
    pub category: CategoryReference,
    /// Current state of the category
    pub state: CategoryState,
    /// Number of outfit files in the category
    pub outfit_count: usize,
    /// Number of worn outfit files in the category
    pub worn_count: usize,
}

impl CategoryInfo {
    pub fn new(category: CategoryReference, state: CategoryState, outfit_count: usize) -> Self {
        Self {
            category,
            state,
            outfit_count,
            worn_count: 0,
        }
    }
    
    #[allow(dead_code)]
    pub fn with_worn_count(mut self, worn_count: usize) -> Self {
        self.worn_count = worn_count;
        self
    }
}

/// Represents an individual outfit file.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FileEntry {
    /// Full path to the file
    pub file_path: PathBuf,
    /// File name only
    pub file_name: String,
    /// Category name (parent directory name)
    pub category_name: String,
    /// Category path (parent directory path)
    pub category_path: PathBuf,
}

impl FileEntry {
    pub fn new(file_path: impl AsRef<Path>) -> Self {
        let path = file_path.as_ref();
        let file_name = path
            .file_name()
            .map(|s| s.to_string_lossy().to_string())
            .unwrap_or_default();
        let category_path = path.parent().unwrap_or(Path::new("")).to_path_buf();
        let category_name = category_path
            .file_name()
            .map(|s| s.to_string_lossy().to_string())
            .unwrap_or_default();

        Self {
            file_path: path.to_path_buf(),
            file_name,
            category_name,
            category_path,
        }
    }

    /// Checks if this is an avatar file.
    pub fn is_avatar_file(&self) -> bool {
        self.file_name.ends_with(".avatar")
    }
}

/// Cache for tracking worn outfits within a category.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CategoryCache {
    /// Set of worn outfit file names
    pub worn_outfits: HashSet<String>,
    /// Total number of outfits in the category
    pub total_outfits: usize,
    /// Last time this cache was updated
    pub last_updated: DateTime<Utc>,
}

impl CategoryCache {
    pub fn new(total_outfits: usize) -> Self {
        Self {
            worn_outfits: HashSet::new(),
            total_outfits,
            last_updated: Utc::now(),
        }
    }

    /// Checks if rotation is complete (all outfits worn).
    pub fn is_rotation_complete(&self) -> bool {
        self.worn_outfits.len() >= self.total_outfits
    }

    /// Returns the rotation progress as a percentage (0.0 to 1.0).
    pub fn rotation_progress(&self) -> f64 {
        if self.total_outfits == 0 {
            return 1.0;
        }
        self.worn_outfits.len() as f64 / self.total_outfits as f64
    }

    /// Returns the number of remaining unworn outfits.
    #[allow(dead_code)]
    pub fn remaining_outfits(&self) -> usize {
        self.total_outfits.saturating_sub(self.worn_outfits.len())
    }

    /// Adds an outfit to the worn set.
    pub fn add_worn(&mut self, file_name: &str) {
        self.worn_outfits.insert(file_name.to_string());
        self.last_updated = Utc::now();
    }

    /// Resets the worn outfits, keeping the total count.
    pub fn reset(&mut self) {
        self.worn_outfits.clear();
        self.last_updated = Utc::now();
    }
}

/// Top-level cache structure for all categories.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OutfitCache {
    /// Cache data per category path
    pub categories: HashMap<String, CategoryCache>,
    /// Cache version for migration support
    pub version: u32,
    /// When the cache was created
    pub created_at: DateTime<Utc>,
}

impl Default for OutfitCache {
    fn default() -> Self {
        Self::new()
    }
}

impl OutfitCache {
    pub fn new() -> Self {
        Self {
            categories: HashMap::new(),
            version: 1,
            created_at: Utc::now(),
        }
    }

    /// Gets or creates a cache entry for a category.
    pub fn get_or_create(&mut self, category_path: &str, total_outfits: usize) -> &mut CategoryCache {
        self.categories
            .entry(category_path.to_string())
            .or_insert_with(|| CategoryCache::new(total_outfits))
    }

    /// Resets all category caches.
    pub fn reset_all(&mut self) {
        for cache in self.categories.values_mut() {
            cache.reset();
        }
    }

    /// Removes a category from the cache.
    #[allow(dead_code)]
    pub fn remove(&mut self, category_path: &str) {
        self.categories.remove(category_path);
    }
}

/// Represents a selected outfit with its context.
#[derive(Debug, Clone, PartialEq)]
pub struct OutfitSelection {
    /// The selected outfit file entry
    pub outfit: FileEntry,
    /// The rotation progress after this selection
    pub rotation_progress: f64,
    /// Whether the rotation was reset for this selection
    pub rotation_was_reset: bool,
}

impl OutfitSelection {
    pub fn new(outfit: FileEntry, rotation_progress: f64, rotation_was_reset: bool) -> Self {
        Self {
            outfit,
            rotation_progress,
            rotation_was_reset,
        }
    }
}
