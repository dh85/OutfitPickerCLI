package entities

import "github.com/dh85/outfitpicker/internal/domain/errors"

// ConfigBuilder provides a fluent API for building Config instances.
type ConfigBuilder struct {
	rootPath           *string
	language           *string
	excludedCategories map[string]bool
	knownCategories    map[string]bool
}

// NewConfigBuilder creates a new ConfigBuilder.
func NewConfigBuilder() *ConfigBuilder {
	return &ConfigBuilder{
		excludedCategories: make(map[string]bool),
		knownCategories:    make(map[string]bool),
	}
}

// RootDirectory sets the root directory path.
func (b *ConfigBuilder) RootDirectory(path string) *ConfigBuilder {
	b.rootPath = &path
	return b
}

// Language sets the language code.
func (b *ConfigBuilder) Language(lang string) *ConfigBuilder {
	b.language = &lang
	return b
}

// Exclude excludes multiple categories using variadic parameters.
func (b *ConfigBuilder) Exclude(categories ...string) *ConfigBuilder {
	for _, cat := range categories {
		b.excludedCategories[cat] = true
	}
	return b
}

// ExcludeCategory excludes a single category.
func (b *ConfigBuilder) ExcludeCategory(category string) *ConfigBuilder {
	b.excludedCategories[category] = true
	return b
}

// Include includes multiple categories using variadic parameters.
func (b *ConfigBuilder) Include(categories ...string) *ConfigBuilder {
	for _, cat := range categories {
		b.knownCategories[cat] = true
	}
	return b
}

// IncludeCategory includes a single category.
func (b *ConfigBuilder) IncludeCategory(category string) *ConfigBuilder {
	b.knownCategories[category] = true
	return b
}

// Build creates a validated Config instance.
func (b *ConfigBuilder) Build() (*Config, error) {
	if b.rootPath == nil {
		return nil, errors.NewInvalidInputError("root directory must be set before building config")
	}

	return NewConfig(
		*b.rootPath,
		b.language,
		b.excludedCategories,
		b.knownCategories,
		nil,
	)
}
