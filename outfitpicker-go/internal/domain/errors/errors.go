package errors

import (
	"errors"
	"fmt"
)

// Top-level errors
var (
	ErrConfigurationNotFound = errors.New("configuration not found")
	ErrCategoryNotFound      = errors.New("category not found")
	ErrNoOutfitsAvailable    = errors.New("no outfits available")
	ErrFileSystem            = errors.New("file system error")
	ErrCache                 = errors.New("cache error")
	ErrInvalidConfiguration  = errors.New("invalid configuration")
)

// Config errors
var (
	ErrPathTraversal     = errors.New("path traversal not allowed")
	ErrPathTooLong       = errors.New("path too long")
	ErrRestrictedPath    = errors.New("restricted path")
	ErrSymlinkNotAllowed = errors.New("symlink not allowed")
	ErrInvalidCharacters = errors.New("invalid characters")
)

// File system errors
var (
	ErrFileNotFound      = errors.New("file not found")
	ErrDirectoryNotFound = errors.New("directory not found")
	ErrPermissionDenied  = errors.New("permission denied")
	ErrInvalidPath       = errors.New("invalid path")
	ErrOperationFailed   = errors.New("operation failed")
)

// Cache errors
var (
	ErrCacheEncoding = errors.New("failed to encode cache data")
	ErrCacheDecoding = errors.New("failed to decode cache data")
	ErrInvalidData   = errors.New("invalid cache data")
)

// Storage errors
var (
	ErrDiskFull      = errors.New("disk full")
	ErrCorruptedData = errors.New("data corrupted")
)

type InvalidInputError struct {
	Message string
}

func (e *InvalidInputError) Error() string {
	return fmt.Sprintf("invalid input: %s", e.Message)
}

func NewInvalidInputError(message string) error {
	return &InvalidInputError{Message: message}
}

type RotationCompletedError struct {
	Category string
}

func (e *RotationCompletedError) Error() string {
	return fmt.Sprintf("all outfits in '%s' have been worn, category has been reset", e.Category)
}

func NewRotationCompletedError(category string) error {
	return &RotationCompletedError{Category: category}
}

var (
	topLevelErrors = []error{
		ErrConfigurationNotFound, ErrCategoryNotFound, ErrNoOutfitsAvailable,
		ErrFileSystem, ErrCache, ErrInvalidConfiguration,
	}
	configErrors = []error{
		ErrPathTraversal, ErrPathTooLong, ErrRestrictedPath,
		ErrSymlinkNotAllowed, ErrInvalidCharacters,
	}
	cacheErrors = []error{
		ErrCacheEncoding, ErrCacheDecoding, ErrInvalidData,
		ErrDiskFull, ErrCorruptedData,
	}
	fileSystemErrors = []error{
		ErrFileNotFound, ErrDirectoryNotFound, ErrPermissionDenied,
		ErrInvalidPath, ErrOperationFailed,
	}
)

func isOneOf(err error, targets []error) bool {
	for _, target := range targets {
		if errors.Is(err, target) {
			return true
		}
	}
	return false
}

// MapError converts lower-level errors to top-level OutfitPickerError cases.
func MapError(err error) error {
	if err == nil {
		return nil
	}

	if isOneOf(err, topLevelErrors) {
		return err
	}

	var invalidInput *InvalidInputError
	if errors.As(err, &invalidInput) {
		return err
	}

	var rotationCompleted *RotationCompletedError
	if errors.As(err, &rotationCompleted) {
		return err
	}

	if isOneOf(err, configErrors) {
		return ErrInvalidConfiguration
	}

	if isOneOf(err, cacheErrors) {
		return ErrCache
	}

	if isOneOf(err, fileSystemErrors) {
		return ErrFileSystem
	}

	return ErrFileSystem
}
