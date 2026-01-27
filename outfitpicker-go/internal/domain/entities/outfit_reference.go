package entities

import (
	"fmt"
	"path/filepath"
)

// OutfitReference references a specific outfit file within a category.
type OutfitReference struct {
	FileName string            `json:"fileName"`
	Category CategoryReference `json:"category"`
}

// NewOutfitReference creates a new outfit reference.
func NewOutfitReference(fileName string, category CategoryReference) OutfitReference {
	return OutfitReference{
		FileName: fileName,
		Category: category,
	}
}

// FilePath returns the complete filesystem path to the outfit file.
func (o OutfitReference) FilePath() string {
	return filepath.Join(o.Category.Path, o.FileName)
}

func (o OutfitReference) String() string {
	return fmt.Sprintf("%s in %s", o.FileName, o.Category.Name)
}
