//! Domain-level validation.
//!
//! This module contains validation logic that belongs in the domain layer.

use crate::domain::error::{ConfigError, Result};
use std::path::Path;

/// Maximum allowed path length.
pub const MAX_PATH_LENGTH: usize = 4096;

/// Restricted path prefixes that should not be used as outfit directories.
const RESTRICTED_PATHS: &[&str] = &[
    "/bin",
    "/sbin",
    "/usr/bin",
    "/usr/sbin",
    "/etc",
    "/var/log",
    "/System",
    "/private/etc",
    "/root/.ssh",
];

/// Domain-level path validation.
///
/// Validates paths for security concerns like:
/// - Path traversal attacks
/// - Restricted system directories
/// - Invalid characters
/// - Path length limits
pub struct PathValidation;

impl PathValidation {
    /// Validates a path for use as an outfit directory.
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

        // Check for invalid characters (control characters)
        if Self::contains_invalid_characters(&path_str) {
            return Err(ConfigError::InvalidCharacters.into());
        }

        Ok(())
    }

    fn contains_path_traversal(path: &str) -> bool {
        path.contains("..") || path.contains("./.")
    }

    fn is_restricted_path(path: &str) -> bool {
        RESTRICTED_PATHS.iter().any(|restricted| {
            path.starts_with(restricted) || path == *restricted
        })
    }

    fn contains_invalid_characters(path: &str) -> bool {
        path.chars().any(|c| c.is_control() && c != '\t')
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_path() {
        assert!(PathValidation::validate(Path::new("/Users/test/outfits")).is_ok());
        assert!(PathValidation::validate(Path::new("./outfits")).is_ok());
        assert!(PathValidation::validate(Path::new("outfits/casual")).is_ok());
    }

    #[test]
    fn test_empty_path() {
        assert!(PathValidation::validate(Path::new("")).is_err());
        assert!(PathValidation::validate(Path::new("   ")).is_err());
    }

    #[test]
    fn test_path_traversal() {
        assert!(PathValidation::validate(Path::new("/path/../etc")).is_err());
        assert!(PathValidation::validate(Path::new("../secret")).is_err());
    }

    #[test]
    fn test_restricted_path() {
        assert!(PathValidation::validate(Path::new("/etc/passwd")).is_err());
        assert!(PathValidation::validate(Path::new("/bin/bash")).is_err());
    }

    #[test]
    fn test_path_too_long() {
        let long_path = "a".repeat(MAX_PATH_LENGTH + 1);
        assert!(PathValidation::validate(Path::new(&long_path)).is_err());
    }

    #[test]
    fn test_valid_long_path() {
        let valid_path = "/".to_string() + &"a".repeat(MAX_PATH_LENGTH - 1);
        assert!(PathValidation::validate(Path::new(&valid_path)).is_ok());
    }
}
