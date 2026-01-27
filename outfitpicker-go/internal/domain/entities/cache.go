package entities

import "time"

// CategoryCache tracks worn outfits for a single category.
type CategoryCache struct {
	WornOutfits  map[string]bool `json:"wornOutfits"`
	TotalOutfits int             `json:"totalOutfits"`
	LastUpdated  time.Time       `json:"lastUpdated"`
}

// NewCategoryCache creates a new category cache.
func NewCategoryCache(totalOutfits int) CategoryCache {
	return CategoryCache{
		WornOutfits:  make(map[string]bool),
		TotalOutfits: totalOutfits,
		LastUpdated:  time.Now(),
	}
}

// IsRotationComplete returns true if all outfits have been worn.
func (c CategoryCache) IsRotationComplete() bool {
	return len(c.WornOutfits) >= c.TotalOutfits
}

// RotationProgress returns the percentage of outfits worn (0.0 to 1.0).
func (c CategoryCache) RotationProgress() float64 {
	if c.TotalOutfits == 0 {
		return 1.0
	}
	return float64(len(c.WornOutfits)) / float64(c.TotalOutfits)
}

// RemainingOutfits returns the number of unworn outfits.
func (c CategoryCache) RemainingOutfits() int {
	remaining := c.TotalOutfits - len(c.WornOutfits)
	if remaining < 0 {
		return 0
	}
	return remaining
}

// Adding returns a new cache with the outfit marked as worn.
func (c CategoryCache) Adding(fileName string) CategoryCache {
	if c.WornOutfits[fileName] {
		return c
	}
	newWorn := make(map[string]bool, len(c.WornOutfits)+1)
	for k, v := range c.WornOutfits {
		newWorn[k] = v
	}
	newWorn[fileName] = true
	return CategoryCache{
		WornOutfits:  newWorn,
		TotalOutfits: c.TotalOutfits,
		LastUpdated:  time.Now(),
	}
}

// Reset returns a new cache with no worn outfits.
func (c CategoryCache) Reset() CategoryCache {
	return NewCategoryCache(c.TotalOutfits)
}

// OutfitCache tracks all category caches.
type OutfitCache struct {
	Categories map[string]CategoryCache `json:"categories"`
	Version    int                      `json:"version"`
	CreatedAt  time.Time                `json:"createdAt"`
}

// NewOutfitCache creates a new outfit cache.
func NewOutfitCache() OutfitCache {
	return OutfitCache{
		Categories: make(map[string]CategoryCache),
		Version:    1,
		CreatedAt:  time.Now(),
	}
}

// Updating returns a new cache with the category updated.
func (o OutfitCache) Updating(path string, cache CategoryCache) OutfitCache {
	newCategories := make(map[string]CategoryCache, len(o.Categories))
	for k, v := range o.Categories {
		newCategories[k] = v
	}
	newCategories[path] = cache
	return OutfitCache{
		Categories: newCategories,
		Version:    o.Version,
		CreatedAt:  o.CreatedAt,
	}
}

// Removing returns a new cache with the category removed.
func (o OutfitCache) Removing(path string) OutfitCache {
	if _, ok := o.Categories[path]; !ok {
		return o
	}
	newCategories := make(map[string]CategoryCache, len(o.Categories)-1)
	for k, v := range o.Categories {
		if k != path {
			newCategories[k] = v
		}
	}
	return OutfitCache{
		Categories: newCategories,
		Version:    o.Version,
		CreatedAt:  o.CreatedAt,
	}
}

// Resetting returns a new cache with the category reset.
func (o OutfitCache) Resetting(path string) *OutfitCache {
	cache, ok := o.Categories[path]
	if !ok {
		return nil
	}
	updated := o.Updating(path, cache.Reset())
	return &updated
}

// ResetAll returns a new cache with all categories reset.
func (o OutfitCache) ResetAll() OutfitCache {
	newCategories := make(map[string]CategoryCache, len(o.Categories))
	for k, v := range o.Categories {
		newCategories[k] = v.Reset()
	}
	return OutfitCache{
		Categories: newCategories,
		Version:    o.Version,
		CreatedAt:  o.CreatedAt,
	}
}
