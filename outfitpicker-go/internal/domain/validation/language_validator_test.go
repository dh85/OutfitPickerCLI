package validation

import (
	"testing"

	"github.com/dh85/outfitpicker/internal/domain/errors"
)

func TestLanguageValidator_Validate(t *testing.T) {
	tests := []struct {
		name     string
		language *string
		wantErr  bool
	}{
		{
			name:     "nil language",
			language: nil,
			wantErr:  false,
		},
		{
			name:     "valid language en",
			language: stringPtr("en"),
			wantErr:  false,
		},
		{
			name:     "valid language es",
			language: stringPtr("es"),
			wantErr:  false,
		},
		{
			name:     "invalid language",
			language: stringPtr("invalid"),
			wantErr:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateLanguage(tt.language)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateLanguage() error = %v, wantErr %v", err, tt.wantErr)
			}
			if err != nil && err != errors.ErrInvalidConfiguration {
				t.Errorf("ValidateLanguage() error = %v, want ErrInvalidConfiguration", err)
			}
		})
	}
}

func TestLanguageValidator_IsSupported(t *testing.T) {
	tests := []struct {
		name     string
		language string
		want     bool
	}{
		{"english", "en", true},
		{"spanish", "es", true},
		{"french", "fr", true},
		{"invalid", "invalid", false},
		{"empty", "", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := IsLanguageSupported(tt.language); got != tt.want {
				t.Errorf("IsLanguageSupported() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestLanguageValidator_SupportedLanguages(t *testing.T) {
	langs := SupportedLanguages()
	if len(langs) == 0 {
		t.Error("SupportedLanguages() returned empty set")
	}
	
	// Check for common languages
	required := []string{"en", "es", "fr", "de"}
	for _, lang := range required {
		if !contains(langs, lang) {
			t.Errorf("SupportedLanguages() missing %s", lang)
		}
	}
}

func stringPtr(s string) *string {
	return &s
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
