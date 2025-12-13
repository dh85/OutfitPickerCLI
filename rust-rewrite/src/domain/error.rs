//! Error types for the outfit picker application.
//!
//! This module defines all error types used throughout the application,
//! providing rich error context and consistent error handling.

use thiserror::Error;

/// Configuration-related errors.
#[derive(Error, Debug, PartialEq, Eq, Clone)]
#[allow(dead_code)]
pub enum ConfigError {
    #[error("root directory cannot be empty")]
    EmptyRoot,

    #[error("root directory not found")]
    MissingRoot,

    #[error("unsupported language: {0}")]
    UnsupportedLanguage(String),

    #[error("path traversal not allowed")]
    PathTraversalNotAllowed,

    #[error("path too long (max 4096 characters)")]
    PathTooLong,

    #[error("restricted path")]
    RestrictedPath,

    #[error("symlink not allowed")]
    SymlinkNotAllowed,

    #[error("invalid characters in path")]
    InvalidCharacters,
}

/// File system operation errors.
#[derive(Error, Debug, PartialEq, Eq, Clone)]
#[allow(dead_code)]
pub enum FileSystemError {
    #[error("file not found: {0}")]
    FileNotFound(String),

    #[error("directory not found: {0}")]
    DirectoryNotFound(String),

    #[error("permission denied: {0}")]
    PermissionDenied(String),

    #[error("invalid path: {0}")]
    InvalidPath(String),

    #[error("operation failed: {0}")]
    OperationFailed(String),
}

/// Cache-related errors.
#[derive(Error, Debug, PartialEq, Eq, Clone)]
#[allow(dead_code)]
pub enum CacheError {
    #[error("failed to encode cache data")]
    EncodingFailed,

    #[error("failed to decode cache data")]
    DecodingFailed,

    #[error("invalid cache data")]
    InvalidData,
}

/// Top-level application errors.
///
/// This enum wraps all domain-specific errors into a single type
/// for consistent error handling at the application level.
#[derive(Error, Debug)]
pub enum OutfitPickerError {
    #[error("configuration error: {0}")]
    Config(#[from] ConfigError),

    #[error("file system error: {0}")]
    FileSystem(#[from] FileSystemError),

    #[error("cache error: {0}")]
    Cache(#[from] CacheError),

    #[error("invalid input: {0}")]
    InvalidInput(String),

    #[error("no outfits available")]
    NoOutfitsAvailable,

    #[error("category not found: {0}")]
    CategoryNotFound(String),

    #[error("io error: {0}")]
    Io(#[from] std::io::Error),

    #[error("serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
}

/// A Result type alias using OutfitPickerError.
pub type Result<T> = std::result::Result<T, OutfitPickerError>;
