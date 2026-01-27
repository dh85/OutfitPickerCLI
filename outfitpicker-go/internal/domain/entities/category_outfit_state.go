package entities

// CategoryOutfitState represents the current state of outfits in a category.
type CategoryOutfitState struct {
	Category         CategoryReference
	AllOutfits       []OutfitReference
	AvailableOutfits []OutfitReference
	WornOutfits      []OutfitReference
}

// NewCategoryOutfitState creates a new category outfit state.
func NewCategoryOutfitState(
	category CategoryReference,
	allOutfits, availableOutfits, wornOutfits []OutfitReference,
) CategoryOutfitState {
	return CategoryOutfitState{
		Category:         category,
		AllOutfits:       allOutfits,
		AvailableOutfits: availableOutfits,
		WornOutfits:      wornOutfits,
	}
}

func (c CategoryOutfitState) TotalCount() int {
	return len(c.AllOutfits)
}

func (c CategoryOutfitState) AvailableCount() int {
	return len(c.AvailableOutfits)
}

func (c CategoryOutfitState) WornCount() int {
	return len(c.WornOutfits)
}

func (c CategoryOutfitState) ProgressPercentage() float64 {
	total := c.TotalCount()
	if total == 0 {
		return 0.0
	}
	return float64(c.WornCount()) / float64(total)
}

func (c CategoryOutfitState) IsRotationComplete() bool {
	return c.WornCount() >= c.TotalCount()
}
