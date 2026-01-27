package errors

import (
	"errors"
	"testing"
)

func TestOutfitPickerError_Error(t *testing.T) {
	tests := []struct {
		err     error
		wantMsg string
	}{
		{ErrConfigurationNotFound, "configuration not found"},
		{ErrCategoryNotFound, "category not found"},
		{ErrNoOutfitsAvailable, "no outfits available"},
		{ErrFileSystem, "file system error"},
		{ErrCache, "cache error"},
		{ErrInvalidConfiguration, "invalid configuration"},
	}

	for _, tt := range tests {
		t.Run(tt.wantMsg, func(t *testing.T) {
			if got := tt.err.Error(); got != tt.wantMsg {
				t.Errorf("Error() = %v, want %v", got, tt.wantMsg)
			}
		})
	}
}

func TestNewInvalidInputError(t *testing.T) {
	err := NewInvalidInputError("root directory cannot be empty")
	want := "invalid input: root directory cannot be empty"
	if got := err.Error(); got != want {
		t.Errorf("Error() = %v, want %v", got, want)
	}
}

func TestNewRotationCompletedError(t *testing.T) {
	err := NewRotationCompletedError("casual")
	want := "all outfits in 'casual' have been worn, category has been reset"
	if got := err.Error(); got != want {
		t.Errorf("Error() = %v, want %v", got, want)
	}
}

func TestMapError(t *testing.T) {
	tests := []struct {
		name string
		err  error
		want error
	}{
		{"nil error", nil, nil},
		{"already top-level", ErrCategoryNotFound, ErrCategoryNotFound},
		{"invalid input", NewInvalidInputError("test"), NewInvalidInputError("test")},
		{"rotation completed", NewRotationCompletedError("casual"), NewRotationCompletedError("casual")},
	}

	configErrors := []struct {
		name string
		err  error
	}{
		{"path traversal", ErrPathTraversal},
		{"path too long", ErrPathTooLong},
		{"restricted path", ErrRestrictedPath},
		{"symlink", ErrSymlinkNotAllowed},
		{"invalid chars", ErrInvalidCharacters},
	}
	for _, ce := range configErrors {
		tests = append(tests, struct {
			name string
			err  error
			want error
		}{"config: " + ce.name, ce.err, ErrInvalidConfiguration})
	}

	cacheErrors := []struct {
		name string
		err  error
	}{
		{"encoding", ErrCacheEncoding},
		{"decoding", ErrCacheDecoding},
		{"invalid data", ErrInvalidData},
		{"disk full", ErrDiskFull},
		{"corrupted", ErrCorruptedData},
	}
	for _, ce := range cacheErrors {
		tests = append(tests, struct {
			name string
			err  error
			want error
		}{"cache: " + ce.name, ce.err, ErrCache})
	}

	fsErrors := []struct {
		name string
		err  error
	}{
		{"not found", ErrFileNotFound},
		{"dir not found", ErrDirectoryNotFound},
		{"permission", ErrPermissionDenied},
		{"invalid path", ErrInvalidPath},
		{"operation failed", ErrOperationFailed},
	}
	for _, fe := range fsErrors {
		tests = append(tests, struct {
			name string
			err  error
			want error
		}{"fs: " + fe.name, fe.err, ErrFileSystem})
	}

	tests = append(tests, struct {
		name string
		err  error
		want error
	}{"unknown", errors.New("unknown"), ErrFileSystem})

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := MapError(tt.err)
			if tt.want == nil {
				if got != nil {
					t.Errorf("MapError() = %v, want nil", got)
				}
				return
			}
			if got.Error() != tt.want.Error() {
				t.Errorf("MapError() = %v, want %v", got, tt.want)
			}
		})
	}
}
