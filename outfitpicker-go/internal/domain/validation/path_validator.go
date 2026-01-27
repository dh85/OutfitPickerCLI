package validation

import (
	"path/filepath"
	"strings"

	"github.com/dh85/outfitpicker/internal/domain/errors"
)

const maxPathLength = 4096

var restrictedPaths = []string{
	"/etc", "/usr", "/bin", "/sbin", "/System", "/private", "/var", "/tmp", "/root",
}

// ValidatePath validates a filesystem path for security issues.
func ValidatePath(path string) error {
	if err := validateCharacters(path); err != nil {
		return err
	}
	if err := validateLength(path); err != nil {
		return err
	}
	if err := validateTraversal(path); err != nil {
		return err
	}
	if err := validateRestrictedPaths(path); err != nil {
		return err
	}
	return nil
}

func validateCharacters(path string) error {
	for _, c := range path {
		if c < 32 || c > 126 {
			return errors.ErrInvalidCharacters
		}
	}
	return nil
}

func validateLength(path string) error {
	if len(path) > maxPathLength {
		return errors.ErrPathTooLong
	}
	return nil
}

func validateTraversal(path string) error {
	if strings.Contains(path, "..") {
		return errors.ErrPathTraversal
	}
	
	cleaned := filepath.Clean(path)
	if strings.Count(path, "/") > strings.Count(cleaned, "/")+2 {
		return errors.ErrPathTraversal
	}
	
	return nil
}

func validateRestrictedPaths(path string) error {
	normalized := strings.ToLower(path)
	for _, restricted := range restrictedPaths {
		if strings.HasPrefix(normalized, strings.ToLower(restricted)) {
			return errors.ErrRestrictedPath
		}
	}
	return nil
}

// MaxPathLength returns the maximum allowed path length.
func MaxPathLength() int {
	return maxPathLength
}

// RestrictedPaths returns the list of restricted paths.
func RestrictedPaths() []string {
	return restrictedPaths
}
