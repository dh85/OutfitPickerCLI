package validation

import (
	"strings"
	"testing"

	"github.com/dh85/outfitpicker/internal/domain/errors"
)

func TestPathValidator_ValidatePath(t *testing.T) {
	tests := []struct {
		name    string
		path    string
		wantErr error
	}{
		{
			name:    "valid path",
			path:    "/home/user/outfits",
			wantErr: nil,
		},
		{
			name:    "path with spaces",
			path:    "/home/user/my outfits",
			wantErr: nil,
		},
		{
			name:    "path traversal with ..",
			path:    "/home/user/../../../etc",
			wantErr: errors.ErrPathTraversal,
		},
		{
			name:    "excessive slashes",
			path:    "/home////user/////outfits",
			wantErr: errors.ErrPathTraversal,
		},
		{
			name:    "path too long",
			path:    "/" + strings.Repeat("a", 5000),
			wantErr: errors.ErrPathTooLong,
		},
		{
			name:    "restricted path /etc",
			path:    "/etc/config",
			wantErr: errors.ErrRestrictedPath,
		},
		{
			name:    "restricted path /usr",
			path:    "/usr/local",
			wantErr: errors.ErrRestrictedPath,
		},
		{
			name:    "invalid characters",
			path:    "/home/user\x00/outfits",
			wantErr: errors.ErrInvalidCharacters,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidatePath(tt.path)
			if tt.wantErr == nil {
				if err != nil {
					t.Errorf("ValidatePath() error = %v, want nil", err)
				}
			} else {
				if err == nil {
					t.Errorf("ValidatePath() error = nil, want %v", tt.wantErr)
				} else if err != tt.wantErr {
					t.Errorf("ValidatePath() error = %v, want %v", err, tt.wantErr)
				}
			}
		})
	}
}

func TestPathValidator_MaxPathLength(t *testing.T) {
	if got := MaxPathLength(); got != 4096 {
		t.Errorf("MaxPathLength() = %v, want 4096", got)
	}
}

func TestPathValidator_RestrictedPaths(t *testing.T) {
	paths := RestrictedPaths()
	if len(paths) == 0 {
		t.Error("RestrictedPaths() returned empty set")
	}

	// Check for common restricted paths
	found := false
	for _, p := range paths {
		if p == "/etc" || p == "/usr" {
			found = true
			break
		}
	}
	if !found {
		t.Error("RestrictedPaths() should contain /etc or /usr")
	}
}
