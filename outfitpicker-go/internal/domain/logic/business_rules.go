package logic

import (
	"strings"

	"github.com/dh85/outfitpicker/internal/domain/entities"
	"github.com/dh85/outfitpicker/internal/domain/errors"
)

const (
	OutfitFileExtension = "avatar"
)

// IsValidOutfitFile checks if a filename is a valid outfit file.
func IsValidOutfitFile(fileName string) bool {
	return strings.HasSuffix(strings.ToLower(fileName), "."+OutfitFileExtension)
}

// IsValidCategoryName checks if a category name is valid.
func IsValidCategoryName(name string) bool {
	return strings.TrimSpace(name) != ""
}

// IsValidOutfitFileName checks if an outfit filename is valid.
func IsValidOutfitFileName(fileName string) bool {
	return strings.TrimSpace(fileName) != ""
}

// CalculateProgress calculates progress percentage for a category.
func CalculateProgress(wornCount, totalCount int) float64 {
	if totalCount == 0 {
		return 1.0
	}
	return float64(wornCount) / float64(totalCount)
}

// IsRotationComplete determines if rotation is complete.
func IsRotationComplete(wornCount, totalCount int) bool {
	return wornCount >= totalCount
}

// ShouldResetRotation determines if a category rotation should be reset.
func ShouldResetRotation(wornCount, totalCount int) bool {
	return wornCount >= totalCount
}

// ValidateCategoryName validates category name and returns error if invalid.
func ValidateCategoryName(categoryName string) error {
	if !IsValidCategoryName(categoryName) {
		return errors.NewInvalidInputError("category name cannot be empty")
	}
	return nil
}

// ValidateOutfit validates outfit and returns error if invalid.
func ValidateOutfit(outfit entities.OutfitReference) error {
	if !IsValidOutfitFileName(outfit.FileName) {
		return errors.NewInvalidInputError("outfit filename cannot be empty")
	}
	return ValidateCategoryName(outfit.Category.Name)
}

// FilterAvailableOutfits filters available outfits based on worn status.
func FilterAvailableOutfits(files []entities.FileEntry, wornOutfits map[string]bool) []entities.FileEntry {
	var available []entities.FileEntry
	for _, file := range files {
		if !wornOutfits[file.FileName] {
			available = append(available, file)
		}
	}
	return available
}
