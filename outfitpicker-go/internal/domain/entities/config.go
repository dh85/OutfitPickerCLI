package entities

import (
	"strings"

	"github.com/dh85/outfitpicker/internal/domain/errors"
	"github.com/dh85/outfitpicker/internal/domain/validation"
)

const DefaultLanguage = "en"

// Config represents the application configuration.
type Config struct {
	Root                string                       `json:"root"`
	Language            string                       `json:"language"`
	ExcludedCategories  map[string]bool              `json:"excludedCategories"`
	KnownCategories     map[string]bool              `json:"knownCategories"`
	KnownCategoryFiles  map[string]map[string]bool   `json:"knownCategoryFiles"`
}

// NewConfig creates and validates a new configuration.
func NewConfig(
	root string,
	language *string,
	excludedCategories map[string]bool,
	knownCategories map[string]bool,
	knownCategoryFiles map[string]map[string]bool,
) (*Config, error) {
	// Validate root is not empty
	if strings.TrimSpace(root) == "" {
		return nil, errors.NewInvalidInputError("root directory cannot be empty")
	}

	// Validate path
	if err := validation.ValidatePath(root); err != nil {
		return nil, errors.MapError(err)
	}

	// Validate language
	if err := validation.ValidateLanguage(language); err != nil {
		return nil, errors.MapError(err)
	}

	// Set default language if not provided
	lang := DefaultLanguage
	if language != nil {
		lang = *language
	}

	// Initialize maps if nil
	if excludedCategories == nil {
		excludedCategories = make(map[string]bool)
	}
	if knownCategories == nil {
		knownCategories = make(map[string]bool)
	}
	if knownCategoryFiles == nil {
		knownCategoryFiles = make(map[string]map[string]bool)
	}

	return &Config{
		Root:               root,
		Language:           lang,
		ExcludedCategories: excludedCategories,
		KnownCategories:    knownCategories,
		KnownCategoryFiles: knownCategoryFiles,
	}, nil
}
