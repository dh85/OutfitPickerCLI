//! Tests for error types and error mapping.

use crate::domain::error::*;

#[cfg(test)]
mod config_error_tests {
    use super::*;

    #[test]
    fn test_config_error_display() {
        assert_eq!(ConfigError::EmptyRoot.to_string(), "root directory cannot be empty");
        assert_eq!(ConfigError::MissingRoot.to_string(), "root directory not found");
        assert_eq!(
            ConfigError::UnsupportedLanguage("xyz".to_string()).to_string(),
            "unsupported language: xyz"
        );
        assert_eq!(
            ConfigError::PathTraversalNotAllowed.to_string(),
            "path traversal not allowed"
        );
        assert_eq!(ConfigError::PathTooLong.to_string(), "path too long (max 4096 characters)");
        assert_eq!(ConfigError::RestrictedPath.to_string(), "restricted path");
        assert_eq!(ConfigError::SymlinkNotAllowed.to_string(), "symlink not allowed");
        assert_eq!(ConfigError::InvalidCharacters.to_string(), "invalid characters in path");
    }

    #[test]
    fn test_config_error_equality() {
        assert_eq!(ConfigError::EmptyRoot, ConfigError::EmptyRoot);
        assert_ne!(ConfigError::EmptyRoot, ConfigError::MissingRoot);
        assert_eq!(
            ConfigError::UnsupportedLanguage("en".to_string()),
            ConfigError::UnsupportedLanguage("en".to_string())
        );
        assert_ne!(
            ConfigError::UnsupportedLanguage("en".to_string()),
            ConfigError::UnsupportedLanguage("fr".to_string())
        );
    }

    #[test]
    fn test_config_error_clone() {
        let err = ConfigError::UnsupportedLanguage("test".to_string());
        let cloned = err.clone();
        assert_eq!(err, cloned);
    }
}

#[cfg(test)]
mod file_system_error_tests {
    use super::*;

    #[test]
    fn test_file_system_error_display() {
        assert_eq!(
            FileSystemError::FileNotFound("test.txt".to_string()).to_string(),
            "file not found: test.txt"
        );
        assert_eq!(
            FileSystemError::DirectoryNotFound("/path".to_string()).to_string(),
            "directory not found: /path"
        );
        assert_eq!(
            FileSystemError::PermissionDenied("/secret".to_string()).to_string(),
            "permission denied: /secret"
        );
        assert_eq!(
            FileSystemError::InvalidPath("bad".to_string()).to_string(),
            "invalid path: bad"
        );
        assert_eq!(
            FileSystemError::OperationFailed("failed".to_string()).to_string(),
            "operation failed: failed"
        );
    }

    #[test]
    fn test_file_system_error_equality() {
        assert_eq!(
            FileSystemError::FileNotFound("a".to_string()),
            FileSystemError::FileNotFound("a".to_string())
        );
        assert_ne!(
            FileSystemError::FileNotFound("a".to_string()),
            FileSystemError::FileNotFound("b".to_string())
        );
    }
}

#[cfg(test)]
mod cache_error_tests {
    use super::*;

    #[test]
    fn test_cache_error_display() {
        assert_eq!(CacheError::EncodingFailed.to_string(), "failed to encode cache data");
        assert_eq!(CacheError::DecodingFailed.to_string(), "failed to decode cache data");
        assert_eq!(CacheError::InvalidData.to_string(), "invalid cache data");
    }

    #[test]
    fn test_cache_error_equality() {
        assert_eq!(CacheError::EncodingFailed, CacheError::EncodingFailed);
        assert_ne!(CacheError::EncodingFailed, CacheError::DecodingFailed);
    }
}

#[cfg(test)]
mod outfit_picker_error_tests {
    use super::*;

    #[test]
    fn test_outfit_picker_error_from_config_error() {
        let config_err = ConfigError::EmptyRoot;
        let picker_err: OutfitPickerError = config_err.into();
        
        match picker_err {
            OutfitPickerError::Config(ConfigError::EmptyRoot) => {}
            _ => panic!("Expected Config error"),
        }
    }

    #[test]
    fn test_outfit_picker_error_from_file_system_error() {
        let fs_err = FileSystemError::FileNotFound("test".to_string());
        let picker_err: OutfitPickerError = fs_err.into();
        
        match picker_err {
            OutfitPickerError::FileSystem(FileSystemError::FileNotFound(path)) => {
                assert_eq!(path, "test");
            }
            _ => panic!("Expected FileSystem error"),
        }
    }

    #[test]
    fn test_outfit_picker_error_from_cache_error() {
        let cache_err = CacheError::DecodingFailed;
        let picker_err: OutfitPickerError = cache_err.into();
        
        match picker_err {
            OutfitPickerError::Cache(CacheError::DecodingFailed) => {}
            _ => panic!("Expected Cache error"),
        }
    }

    #[test]
    fn test_outfit_picker_error_invalid_input() {
        let err = OutfitPickerError::InvalidInput("test message".to_string());
        assert_eq!(err.to_string(), "invalid input: test message");
    }

    #[test]
    fn test_outfit_picker_error_no_outfits_available() {
        let err = OutfitPickerError::NoOutfitsAvailable;
        assert_eq!(err.to_string(), "no outfits available");
    }

    #[test]
    fn test_outfit_picker_error_category_not_found() {
        let err = OutfitPickerError::CategoryNotFound("TestCategory".to_string());
        assert_eq!(err.to_string(), "category not found: TestCategory");
    }

    #[test]
    fn test_result_type_alias() {
        fn test_fn() -> Result<i32> {
            Ok(42)
        }
        
        fn test_fn_err() -> Result<i32> {
            Err(OutfitPickerError::NoOutfitsAvailable)
        }
        
        assert_eq!(test_fn().unwrap(), 42);
        assert!(test_fn_err().is_err());
    }
}

#[cfg(test)]
mod error_conversion_tests {
    use super::*;

    #[test]
    fn test_question_mark_operator_config_error() {
        fn inner() -> Result<()> {
            Err(ConfigError::EmptyRoot)?
        }
        
        let result = inner();
        assert!(matches!(result, Err(OutfitPickerError::Config(_))));
    }

    #[test]
    fn test_question_mark_operator_file_system_error() {
        fn inner() -> Result<()> {
            Err(FileSystemError::FileNotFound("test".to_string()))?
        }
        
        let result = inner();
        assert!(matches!(result, Err(OutfitPickerError::FileSystem(_))));
    }

    #[test]
    fn test_question_mark_operator_cache_error() {
        fn inner() -> Result<()> {
            Err(CacheError::InvalidData)?
        }
        
        let result = inner();
        assert!(matches!(result, Err(OutfitPickerError::Cache(_))));
    }
}
