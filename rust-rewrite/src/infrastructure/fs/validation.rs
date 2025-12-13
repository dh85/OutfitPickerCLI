//! Path validation utilities.
//!
//! This module provides security-focused path validation to prevent
//! path traversal attacks and access to restricted system directories.

use std::path::Path;

use crate::domain::error::{ConfigError, Result};

/// Maximum allowed path length.
pub const MAX_PATH_LENGTH: usize = 4096;

/// Restricted paths that should never be accessed.
const RESTRICTED_PATHS: &[&str] = &[
    "/etc",
    "/usr/bin",
    "/usr/sbin",
    "/bin",
    "/sbin",
    "/var/log",
    "/System",
    "/Library",
    "/private",
    "/root",
];

/// Path validator for security checks.
pub struct PathValidator;

impl PathValidator {
    /// Validates a path for security issues.
    ///
    /// Checks for:
    /// - Empty paths
    /// - Path traversal attempts (..)
    /// - Excessive path length
    /// - Restricted system directories
    /// - Invalid characters
    pub fn validate(path: &Path) -> Result<()> {
        let path_str = path.to_string_lossy();

        // Check for empty path
        if path_str.trim().is_empty() {
            return Err(ConfigError::EmptyRoot.into());
        }

        // Check path length
        if path_str.len() > MAX_PATH_LENGTH {
            return Err(ConfigError::PathTooLong.into());
        }

        // Check for path traversal
        if Self::contains_path_traversal(&path_str) {
            return Err(ConfigError::PathTraversalNotAllowed.into());
        }

        // Check for restricted paths
        if Self::is_restricted_path(&path_str) {
            return Err(ConfigError::RestrictedPath.into());
        }

        // Check for invalid characters
        if Self::contains_invalid_characters(&path_str) {
            return Err(ConfigError::InvalidCharacters.into());
        }

        Ok(())
    }

    /// Checks if the path contains traversal attempts.
    fn contains_path_traversal(path: &str) -> bool {
        // Normalize and check for ..
        let components: Vec<&str> = path.split('/').collect();
        let mut depth = 0i32;

        for component in components {
            match component {
                ".." => {
                    depth -= 1;
                    if depth < 0 {
                        return true;
                    }
                }
                "." | "" => {}
                _ => depth += 1,
            }
        }

        // Also check for literal .. in the path
        path.contains("/..")
    }

    /// Checks if the path is a restricted system directory.
    fn is_restricted_path(path: &str) -> bool {
        RESTRICTED_PATHS.iter().any(|restricted| {
            path.starts_with(restricted) || path == *restricted
        })
    }

    /// Checks for invalid characters in the path.
    fn contains_invalid_characters(path: &str) -> bool {
        // Check for control characters
        path.chars().any(|c| c.is_control())
    }

    /// Returns the maximum allowed path length.
    #[allow(dead_code)]
    pub fn max_path_length() -> usize {
        MAX_PATH_LENGTH
    }

    /// Returns the list of restricted paths.
    #[allow(dead_code)]
    pub fn restricted_paths() -> &'static [&'static str] {
        RESTRICTED_PATHS
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_path() {
        assert!(PathValidator::validate(Path::new("/home/user/outfits")).is_ok());
        assert!(PathValidator::validate(Path::new("./outfits")).is_ok());
        assert!(PathValidator::validate(Path::new("outfits/casual")).is_ok());
    }

    #[test]
    fn test_empty_path() {
        assert!(PathValidator::validate(Path::new("")).is_err());
        assert!(PathValidator::validate(Path::new("   ")).is_err());
    }

    #[test]
    fn test_path_traversal() {
        assert!(PathValidator::validate(Path::new("../etc/passwd")).is_err());
        assert!(PathValidator::validate(Path::new("/home/../etc")).is_err());
        assert!(PathValidator::validate(Path::new("./../../secret")).is_err());
    }

    #[test]
    fn test_restricted_path() {
        assert!(PathValidator::validate(Path::new("/etc/passwd")).is_err());
        assert!(PathValidator::validate(Path::new("/usr/bin/sudo")).is_err());
        assert!(PathValidator::validate(Path::new("/var/log")).is_err());
    }

    #[test]
    fn test_path_too_long() {
        let long_path = "/".to_string() + &"a".repeat(MAX_PATH_LENGTH + 1);
        assert!(PathValidator::validate(Path::new(&long_path)).is_err());
    }

    #[test]
    fn test_path_just_under_limit() {
        let long_path = "/".to_string() + &"a".repeat(MAX_PATH_LENGTH - 2);
        assert!(PathValidator::validate(Path::new(&long_path)).is_ok());
    }

    #[test]
    fn test_control_characters_rejected() {
        assert!(PathValidator::validate(Path::new("/home/user\x00outfits")).is_err());
        assert!(PathValidator::validate(Path::new("/home/user\noutfits")).is_err());
        assert!(PathValidator::validate(Path::new("/home/user\toutfits")).is_err());
    }

    #[test]
    fn test_max_path_length_getter() {
        assert_eq!(PathValidator::max_path_length(), MAX_PATH_LENGTH);
    }

    #[test]
    fn test_restricted_paths_getter() {
        let paths = PathValidator::restricted_paths();
        assert!(paths.contains(&"/etc"));
        assert!(paths.contains(&"/usr/bin"));
    }

    #[test]
    fn test_safe_subdirectory_of_restricted() {
        // These should be restricted since they start with restricted paths
        assert!(PathValidator::validate(Path::new("/etc/passwd")).is_err());
        assert!(PathValidator::validate(Path::new("/System/Library")).is_err());
    }

    #[test]
    fn test_similar_but_not_restricted_path() {
        // These should NOT be restricted - they just happen to contain restricted path as substring
        // e.g., "/home/user/etc" is fine because it doesn't START with /etc
        assert!(PathValidator::validate(Path::new("/home/user/etc")).is_ok());
        assert!(PathValidator::validate(Path::new("/home/user/Library")).is_ok());
    }

    #[test]
    fn test_dot_only_path() {
        // A single dot is a valid relative path
        assert!(PathValidator::validate(Path::new(".")).is_ok());
    }

    #[test]
    fn test_absolute_vs_relative_paths() {
        assert!(PathValidator::validate(Path::new("/Users/test/outfits")).is_ok());
        assert!(PathValidator::validate(Path::new("./test/outfits")).is_ok());
        assert!(PathValidator::validate(Path::new("test/outfits")).is_ok());
    }
}
