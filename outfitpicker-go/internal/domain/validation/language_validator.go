package validation

import "github.com/dh85/outfitpicker/internal/domain/errors"

var supportedLanguages = []string{
	"en", "es", "fr", "de", "it", "pt", "nl", "ru", "ja", "zh",
	"ko", "ar", "hi", "no", "sv", "fi", "da", "pl", "hu", "hr",
	"sr", "ro", "el", "bg", "tr", "lt", "lv", "et", "is", "ca",
	"uk", "mt", "sk", "cs", "sl", "bn", "vi", "th", "he", "id",
	"ms", "ta", "te", "gu", "pa", "ur", "sw", "am", "yo", "zu", "af",
}

// ValidateLanguage validates a language code.
func ValidateLanguage(language *string) error {
	if language == nil {
		return nil
	}

	if !IsLanguageSupported(*language) {
		return errors.ErrInvalidConfiguration
	}

	return nil
}

// IsLanguageSupported checks if a language code is supported.
func IsLanguageSupported(language string) bool {
	for _, supported := range supportedLanguages {
		if supported == language {
			return true
		}
	}
	return false
}

// SupportedLanguages returns all supported language codes.
func SupportedLanguages() []string {
	return supportedLanguages
}
