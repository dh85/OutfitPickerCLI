package entities

// SelectionTarget specifies the scope for outfit selection operations.
type SelectionTarget interface {
	isSelectionTarget()
}

// SelectionTargetCategory selects from a single category.
type SelectionTargetCategory struct {
	Category CategoryReference `json:"category"`
}

func (SelectionTargetCategory) isSelectionTarget() {}

// SelectionTargetAllCategories selects from all available categories.
type SelectionTargetAllCategories struct{}

func (SelectionTargetAllCategories) isSelectionTarget() {}

// SelectionTargetCategories selects from a specific set of categories.
type SelectionTargetCategories struct {
	Categories []CategoryReference `json:"categories"`
}

func (SelectionTargetCategories) isSelectionTarget() {}

// RotationProgress tracks rotation progress for a specific category.
type RotationProgress struct {
	Category         CategoryReference `json:"category"`
	WornCount        int               `json:"wornCount"`
	TotalOutfitCount int               `json:"totalOutfitCount"`
}

// NewRotationProgress creates a new rotation progress.
func NewRotationProgress(category CategoryReference, wornCount, totalOutfitCount int) RotationProgress {
	return RotationProgress{
		Category:         category,
		WornCount:        wornCount,
		TotalOutfitCount: totalOutfitCount,
	}
}

// Progress returns progress as a value between 0.0 and 1.0.
func (r RotationProgress) Progress() float64 {
	if r.TotalOutfitCount == 0 {
		return 1.0
	}
	return float64(r.WornCount) / float64(r.TotalOutfitCount)
}

// IsComplete returns whether the rotation cycle is complete.
func (r RotationProgress) IsComplete() bool {
	return r.WornCount >= r.TotalOutfitCount
}

// AvailableCount returns the number of outfits available for selection.
func (r RotationProgress) AvailableCount() int {
	if r.IsComplete() {
		return r.TotalOutfitCount
	}
	return r.TotalOutfitCount - r.WornCount
}
