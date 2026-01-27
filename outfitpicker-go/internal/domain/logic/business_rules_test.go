package logic

import (
	"testing"

	"github.com/dh85/outfitpicker/internal/domain/entities"
)

func TestBusinessRules_Constants(t *testing.T) {
	if OutfitFileExtension != "avatar" {
		t.Errorf("OutfitFileExtension = %v, want avatar", OutfitFileExtension)
	}
}

func TestIsValidOutfitFile(t *testing.T) {
	tests := []struct {
		name     string
		fileName string
		want     bool
	}{
		{"valid avatar file", "outfit.avatar", true},
		{"valid uppercase", "OUTFIT.AVATAR", true},
		{"valid mixed case", "Outfit.Avatar", true},
		{"invalid extension", "outfit.txt", false},
		{"no extension", "outfit", false},
		{"empty string", "", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := IsValidOutfitFile(tt.fileName); got != tt.want {
				t.Errorf("IsValidOutfitFile() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestIsValidCategoryName(t *testing.T) {
	tests := []struct {
		name string
		cat  string
		want bool
	}{
		{"valid name", "casual", true},
		{"name with spaces", "work attire", true},
		{"empty string", "", false},
		{"only whitespace", "   ", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := IsValidCategoryName(tt.cat); got != tt.want {
				t.Errorf("IsValidCategoryName() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestCalculateProgress(t *testing.T) {
	tests := []struct {
		name       string
		wornCount  int
		totalCount int
		want       float64
	}{
		{"30% complete", 3, 10, 0.3},
		{"50% complete", 5, 10, 0.5},
		{"100% complete", 10, 10, 1.0},
		{"zero total", 0, 0, 1.0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := CalculateProgress(tt.wornCount, tt.totalCount); got != tt.want {
				t.Errorf("CalculateProgress() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestIsRotationComplete(t *testing.T) {
	tests := []struct {
		name       string
		wornCount  int
		totalCount int
		want       bool
	}{
		{"not complete", 3, 10, false},
		{"complete", 10, 10, true},
		{"over complete", 11, 10, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := IsRotationComplete(tt.wornCount, tt.totalCount); got != tt.want {
				t.Errorf("IsRotationComplete() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestShouldResetRotation(t *testing.T) {
	tests := []struct {
		name       string
		wornCount  int
		totalCount int
		want       bool
	}{
		{"should not reset", 3, 10, false},
		{"should reset", 10, 10, true},
		{"should reset over", 11, 10, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := ShouldResetRotation(tt.wornCount, tt.totalCount); got != tt.want {
				t.Errorf("ShouldResetRotation() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestValidateCategoryName(t *testing.T) {
	tests := []struct {
		name    string
		catName string
		wantErr bool
	}{
		{"valid name", "casual", false},
		{"empty name", "", true},
		{"whitespace only", "   ", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateCategoryName(tt.catName)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateCategoryName() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidateOutfit(t *testing.T) {
	category := entities.NewCategoryReference("casual", "/path/to/casual")
	
	tests := []struct {
		name    string
		outfit  entities.OutfitReference
		wantErr bool
	}{
		{
			name:    "valid outfit",
			outfit:  entities.NewOutfitReference("outfit.avatar", category),
			wantErr: false,
		},
		{
			name:    "empty filename",
			outfit:  entities.NewOutfitReference("", category),
			wantErr: true,
		},
		{
			name:    "whitespace filename",
			outfit:  entities.NewOutfitReference("   ", category),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateOutfit(tt.outfit)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateOutfit() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestFilterAvailableOutfits(t *testing.T) {
	files := []entities.FileEntry{
		entities.NewFileEntry("/path/to/casual/outfit1.avatar"),
		entities.NewFileEntry("/path/to/casual/outfit2.avatar"),
		entities.NewFileEntry("/path/to/casual/outfit3.avatar"),
	}
	
	worn := map[string]bool{
		"outfit1.avatar": true,
		"outfit3.avatar": true,
	}

	available := FilterAvailableOutfits(files, worn)
	
	if len(available) != 1 {
		t.Errorf("FilterAvailableOutfits() length = %v, want 1", len(available))
	}
	if len(available) > 0 && available[0].FileName != "outfit2.avatar" {
		t.Errorf("FilterAvailableOutfits()[0].FileName = %v, want outfit2.avatar", available[0].FileName)
	}
}
