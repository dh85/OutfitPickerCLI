//! Tests for domain models.
//!
//! This module contains comprehensive tests for all domain entities.

use crate::domain::models::*;
use std::collections::HashSet;
use std::path::PathBuf;

// ============================================================================
// Config Tests
// ============================================================================

#[cfg(test)]
mod config_tests {
    use super::*;
    use crate::domain::error::OutfitPickerError;

    #[test]
    fn test_config_new_valid_path() {
        let config = Config::new("/valid/path", Some("en".to_string()));
        assert!(config.is_ok());
        let config = config.unwrap();
        assert_eq!(config.root, PathBuf::from("/valid/path"));
        assert_eq!(config.language, Some("en".to_string()));
    }

    #[test]
    fn test_config_new_no_language() {
        let config = Config::new("/valid/path", None);
        assert!(config.is_ok());
        assert_eq!(config.unwrap().language, None);
    }

    #[test]
    fn test_config_empty_path_fails() {
        let result = Config::new("", Some("en".to_string()));
        assert!(result.is_err());
    }

    #[test]
    fn test_config_whitespace_path_fails() {
        let result = Config::new("   ", Some("en".to_string()));
        assert!(result.is_err());
    }

    #[test]
    fn test_config_path_traversal_fails() {
        let result = Config::new("/path/../etc/passwd", Some("en".to_string()));
        assert!(result.is_err());
    }

    #[test]
    fn test_config_restricted_path_fails() {
        let result = Config::new("/etc/passwd", Some("en".to_string()));
        assert!(result.is_err());
    }

    #[test]
    fn test_config_unsupported_language_fails() {
        let result = Config::new("/valid/path", Some("xyz".to_string()));
        assert!(result.is_err());
        match result {
            Err(OutfitPickerError::Config(_)) => {}
            _ => panic!("Expected ConfigError"),
        }
    }

    #[test]
    fn test_config_with_exclusions() {
        let mut excluded = HashSet::new();
        excluded.insert("Category1".to_string());
        excluded.insert("Category2".to_string());

        let config = Config::with_exclusions("/valid/path", Some("en".to_string()), excluded);
        assert!(config.is_ok());
        let config = config.unwrap();
        assert!(config.excluded_categories.contains("Category1"));
        assert!(config.excluded_categories.contains("Category2"));
    }

    #[test]
    fn test_config_default_language() {
        assert_eq!(Config::default_language(), "en");
    }

    #[test]
    fn test_config_is_supported_language() {
        assert!(Config::is_supported_language("en"));
        assert!(Config::is_supported_language("es"));
        assert!(Config::is_supported_language("fr"));
        assert!(Config::is_supported_language("de"));
        assert!(Config::is_supported_language("ja"));
        assert!(Config::is_supported_language("zh"));
        assert!(!Config::is_supported_language("xyz"));
        assert!(!Config::is_supported_language(""));
    }

    #[test]
    fn test_config_supported_languages_not_empty() {
        assert!(!Config::supported_languages().is_empty());
        assert!(Config::supported_languages().len() > 40);
    }

    #[test]
    fn test_config_serialization_roundtrip() {
        let config = Config::new("/valid/path", Some("en".to_string())).unwrap();
        let json = serde_json::to_string(&config).unwrap();
        let deserialized: Config = serde_json::from_str(&json).unwrap();
        assert_eq!(config, deserialized);
    }
}

// ============================================================================
// CategoryCache Tests
// ============================================================================

#[cfg(test)]
mod category_cache_tests {
    use super::*;

    #[test]
    fn test_category_cache_new() {
        let cache = CategoryCache::new(5);
        assert_eq!(cache.total_outfits, 5);
        assert!(cache.worn_outfits.is_empty());
    }

    #[test]
    fn test_category_cache_add_worn() {
        let mut cache = CategoryCache::new(5);
        cache.add_worn("outfit1.avatar");
        cache.add_worn("outfit2.avatar");
        
        assert_eq!(cache.worn_outfits.len(), 2);
        assert!(cache.worn_outfits.contains("outfit1.avatar"));
        assert!(cache.worn_outfits.contains("outfit2.avatar"));
    }

    #[test]
    fn test_category_cache_add_worn_duplicate() {
        let mut cache = CategoryCache::new(5);
        cache.add_worn("outfit1.avatar");
        cache.add_worn("outfit1.avatar");
        
        assert_eq!(cache.worn_outfits.len(), 1);
    }

    #[test]
    fn test_category_cache_is_rotation_complete() {
        let mut cache = CategoryCache::new(3);
        assert!(!cache.is_rotation_complete());
        
        cache.add_worn("outfit1.avatar");
        assert!(!cache.is_rotation_complete());
        
        cache.add_worn("outfit2.avatar");
        assert!(!cache.is_rotation_complete());
        
        cache.add_worn("outfit3.avatar");
        assert!(cache.is_rotation_complete());
    }

    #[test]
    fn test_category_cache_rotation_progress() {
        let mut cache = CategoryCache::new(4);
        assert_eq!(cache.rotation_progress(), 0.0);
        
        cache.add_worn("outfit1.avatar");
        assert_eq!(cache.rotation_progress(), 0.25);
        
        cache.add_worn("outfit2.avatar");
        assert_eq!(cache.rotation_progress(), 0.5);
        
        cache.add_worn("outfit3.avatar");
        assert_eq!(cache.rotation_progress(), 0.75);
        
        cache.add_worn("outfit4.avatar");
        assert_eq!(cache.rotation_progress(), 1.0);
    }

    #[test]
    fn test_category_cache_rotation_progress_zero_total() {
        let cache = CategoryCache::new(0);
        assert_eq!(cache.rotation_progress(), 1.0);
    }

    #[test]
    fn test_category_cache_remaining_outfits() {
        let mut cache = CategoryCache::new(5);
        assert_eq!(cache.remaining_outfits(), 5);
        
        cache.add_worn("outfit1.avatar");
        assert_eq!(cache.remaining_outfits(), 4);
        
        cache.add_worn("outfit2.avatar");
        cache.add_worn("outfit3.avatar");
        assert_eq!(cache.remaining_outfits(), 2);
    }

    #[test]
    fn test_category_cache_reset() {
        let mut cache = CategoryCache::new(5);
        cache.add_worn("outfit1.avatar");
        cache.add_worn("outfit2.avatar");
        
        cache.reset();
        
        assert!(cache.worn_outfits.is_empty());
        assert_eq!(cache.total_outfits, 5);
    }

    #[test]
    fn test_category_cache_serialization_roundtrip() {
        let mut cache = CategoryCache::new(5);
        cache.add_worn("outfit1.avatar");
        cache.add_worn("outfit2.avatar");
        
        let json = serde_json::to_string(&cache).unwrap();
        let deserialized: CategoryCache = serde_json::from_str(&json).unwrap();
        
        assert_eq!(cache.worn_outfits, deserialized.worn_outfits);
        assert_eq!(cache.total_outfits, deserialized.total_outfits);
    }
}

// ============================================================================
// OutfitCache Tests
// ============================================================================

#[cfg(test)]
mod outfit_cache_tests {
    use super::*;

    #[test]
    fn test_outfit_cache_new() {
        let cache = OutfitCache::new();
        assert!(cache.categories.is_empty());
        assert_eq!(cache.version, 1);
    }

    #[test]
    fn test_outfit_cache_default() {
        let cache = OutfitCache::default();
        assert!(cache.categories.is_empty());
    }

    #[test]
    fn test_outfit_cache_get_or_create_new() {
        let mut cache = OutfitCache::new();
        let category_cache = cache.get_or_create("/path/Category1", 5);
        
        assert_eq!(category_cache.total_outfits, 5);
        assert!(category_cache.worn_outfits.is_empty());
    }

    #[test]
    fn test_outfit_cache_get_or_create_existing() {
        let mut cache = OutfitCache::new();
        
        {
            let category_cache = cache.get_or_create("/path/Category1", 5);
            category_cache.add_worn("outfit1.avatar");
        }
        
        let category_cache = cache.get_or_create("/path/Category1", 10);
        
        // Should return existing cache, not create new one
        assert_eq!(category_cache.total_outfits, 5);
        assert!(category_cache.worn_outfits.contains("outfit1.avatar"));
    }

    #[test]
    fn test_outfit_cache_reset_all() {
        let mut cache = OutfitCache::new();
        
        cache.get_or_create("/path/Category1", 5).add_worn("outfit1.avatar");
        cache.get_or_create("/path/Category2", 3).add_worn("outfit2.avatar");
        
        cache.reset_all();
        
        assert!(cache.categories.get("/path/Category1").unwrap().worn_outfits.is_empty());
        assert!(cache.categories.get("/path/Category2").unwrap().worn_outfits.is_empty());
    }

    #[test]
    fn test_outfit_cache_remove() {
        let mut cache = OutfitCache::new();
        cache.get_or_create("/path/Category1", 5);
        cache.get_or_create("/path/Category2", 3);
        
        cache.remove("/path/Category1");
        
        assert!(!cache.categories.contains_key("/path/Category1"));
        assert!(cache.categories.contains_key("/path/Category2"));
    }

    #[test]
    fn test_outfit_cache_serialization_roundtrip() {
        let mut cache = OutfitCache::new();
        cache.get_or_create("/path/Category1", 5).add_worn("outfit1.avatar");
        cache.get_or_create("/path/Category2", 3).add_worn("outfit2.avatar");
        
        let json = serde_json::to_string(&cache).unwrap();
        let deserialized: OutfitCache = serde_json::from_str(&json).unwrap();
        
        assert_eq!(cache.categories.len(), deserialized.categories.len());
        assert_eq!(cache.version, deserialized.version);
    }
}

// ============================================================================
// FileEntry Tests
// ============================================================================

#[cfg(test)]
mod file_entry_tests {
    use super::*;

    #[test]
    fn test_file_entry_new() {
        let entry = FileEntry::new("/path/Category1/outfit.avatar");
        
        assert_eq!(entry.file_path, PathBuf::from("/path/Category1/outfit.avatar"));
        assert_eq!(entry.file_name, "outfit.avatar");
        assert_eq!(entry.category_name, "Category1");
        assert_eq!(entry.category_path, PathBuf::from("/path/Category1"));
    }

    #[test]
    fn test_file_entry_is_avatar_file() {
        let avatar = FileEntry::new("/path/Category1/outfit.avatar");
        let text = FileEntry::new("/path/Category1/readme.txt");
        let png = FileEntry::new("/path/Category1/image.png");
        
        assert!(avatar.is_avatar_file());
        assert!(!text.is_avatar_file());
        assert!(!png.is_avatar_file());
    }

    #[test]
    fn test_file_entry_nested_path() {
        let entry = FileEntry::new("/root/parent/Category/outfit.avatar");
        
        assert_eq!(entry.category_name, "Category");
        assert_eq!(entry.file_name, "outfit.avatar");
    }

    #[test]
    fn test_file_entry_equality() {
        let entry1 = FileEntry::new("/path/Category1/outfit.avatar");
        let entry2 = FileEntry::new("/path/Category1/outfit.avatar");
        let entry3 = FileEntry::new("/path/Category1/different.avatar");
        
        assert_eq!(entry1, entry2);
        assert_ne!(entry1, entry3);
    }
}

// ============================================================================
// CategoryReference Tests
// ============================================================================

#[cfg(test)]
mod category_reference_tests {
    use super::*;

    #[test]
    fn test_category_reference_new() {
        let cat_ref = CategoryReference::new("Category1", "/path/Category1");
        
        assert_eq!(cat_ref.name, "Category1");
        assert_eq!(cat_ref.path, PathBuf::from("/path/Category1"));
    }

    #[test]
    fn test_category_reference_equality() {
        let ref1 = CategoryReference::new("Category1", "/path/Category1");
        let ref2 = CategoryReference::new("Category1", "/path/Category1");
        let ref3 = CategoryReference::new("Category2", "/path/Category2");
        
        assert_eq!(ref1, ref2);
        assert_ne!(ref1, ref3);
    }

    #[test]
    fn test_category_reference_hash() {
        let mut set = HashSet::new();
        set.insert(CategoryReference::new("Category1", "/path/Category1"));
        set.insert(CategoryReference::new("Category1", "/path/Category1"));
        set.insert(CategoryReference::new("Category2", "/path/Category2"));
        
        assert_eq!(set.len(), 2);
    }

    #[test]
    fn test_category_reference_serialization_roundtrip() {
        let cat_ref = CategoryReference::new("Category1", "/path/Category1");
        
        let json = serde_json::to_string(&cat_ref).unwrap();
        let deserialized: CategoryReference = serde_json::from_str(&json).unwrap();
        
        assert_eq!(cat_ref, deserialized);
    }
}

// ============================================================================
// CategoryInfo Tests
// ============================================================================

#[cfg(test)]
mod category_info_tests {
    use super::*;

    #[test]
    fn test_category_info_new() {
        let cat_ref = CategoryReference::new("Category1", "/path/Category1");
        let info = CategoryInfo::new(cat_ref.clone(), CategoryState::HasOutfits, 5);
        
        assert_eq!(info.category, cat_ref);
        assert_eq!(info.state, CategoryState::HasOutfits);
        assert_eq!(info.outfit_count, 5);
        assert_eq!(info.worn_count, 0);
    }

    #[test]
    fn test_category_info_with_worn_count() {
        let cat_ref = CategoryReference::new("Category1", "/path/Category1");
        let info = CategoryInfo::new(cat_ref, CategoryState::HasOutfits, 5)
            .with_worn_count(3);
        
        assert_eq!(info.worn_count, 3);
    }

    #[test]
    fn test_category_state_variants() {
        let states = [
            CategoryState::HasOutfits,
            CategoryState::Empty,
            CategoryState::NoAvatarFiles,
            CategoryState::UserExcluded,
        ];
        
        for state in states {
            let json = serde_json::to_string(&state).unwrap();
            let deserialized: CategoryState = serde_json::from_str(&json).unwrap();
            assert_eq!(state, deserialized);
        }
    }
}

// ============================================================================
// OutfitSelection Tests
// ============================================================================

#[cfg(test)]
mod outfit_selection_tests {
    use super::*;

    #[test]
    fn test_outfit_selection_new() {
        let outfit = FileEntry::new("/path/Category1/outfit.avatar");
        let selection = OutfitSelection::new(outfit.clone(), 0.5, false);
        
        assert_eq!(selection.outfit, outfit);
        assert_eq!(selection.rotation_progress, 0.5);
        assert!(!selection.rotation_was_reset);
    }

    #[test]
    fn test_outfit_selection_with_reset() {
        let outfit = FileEntry::new("/path/Category1/outfit.avatar");
        let selection = OutfitSelection::new(outfit, 0.25, true);
        
        assert!(selection.rotation_was_reset);
        assert_eq!(selection.rotation_progress, 0.25);
    }

    #[test]
    fn test_outfit_selection_equality() {
        let outfit = FileEntry::new("/path/Category1/outfit.avatar");
        let selection1 = OutfitSelection::new(outfit.clone(), 0.5, false);
        let selection2 = OutfitSelection::new(outfit.clone(), 0.5, false);
        let selection3 = OutfitSelection::new(outfit, 0.75, false);
        
        assert_eq!(selection1, selection2);
        assert_ne!(selection1, selection3);
    }
}
