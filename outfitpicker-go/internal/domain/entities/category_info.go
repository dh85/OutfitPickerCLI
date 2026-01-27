package entities

// CategoryState represents the current state of a category directory.
type CategoryState string

const (
	CategoryStateHasOutfits     CategoryState = "hasOutfits"
	CategoryStateEmpty          CategoryState = "empty"
	CategoryStateNoAvatarFiles  CategoryState = "noAvatarFiles"
	CategoryStateUserExcluded   CategoryState = "userExcluded"
)

// CategoryInfo combines a category with its current state information.
type CategoryInfo struct {
	Category    CategoryReference `json:"category"`
	State       CategoryState     `json:"state"`
	OutfitCount int               `json:"outfitCount"`
}

// NewCategoryInfo creates a new category info.
func NewCategoryInfo(category CategoryReference, state CategoryState, outfitCount int) CategoryInfo {
	return CategoryInfo{
		Category:    category,
		State:       state,
		OutfitCount: outfitCount,
	}
}
