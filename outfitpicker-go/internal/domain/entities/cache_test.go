package entities

import (
	"encoding/json"
	"testing"
)

func TestNewCategoryCache(t *testing.T) {
	cache := NewCategoryCache(10)

	if cache.TotalOutfits != 10 {
		t.Errorf("TotalOutfits = %v, want 10", cache.TotalOutfits)
	}
	if len(cache.WornOutfits) != 0 {
		t.Errorf("WornOutfits length = %v, want 0", len(cache.WornOutfits))
	}
}

func TestCategoryCache_IsRotationComplete(t *testing.T) {
	tests := []struct {
		name  string
		cache CategoryCache
		want  bool
	}{
		{
			name:  "no outfits worn",
			cache: NewCategoryCache(5),
			want:  false,
		},
		{
			name:  "some outfits worn",
			cache: NewCategoryCache(5).Adding("outfit1.avatar"),
			want:  false,
		},
		{
			name: "all outfits worn",
			cache: NewCategoryCache(2).
				Adding("outfit1.avatar").
				Adding("outfit2.avatar"),
			want: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.cache.IsRotationComplete(); got != tt.want {
				t.Errorf("IsRotationComplete() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestCategoryCache_Adding(t *testing.T) {
	cache := NewCategoryCache(5)

	updated := cache.Adding("outfit1.avatar")
	if len(updated.WornOutfits) != 1 {
		t.Errorf("WornOutfits length = %v, want 1", len(updated.WornOutfits))
	}
	if !updated.WornOutfits["outfit1.avatar"] {
		t.Error("outfit1.avatar should be in WornOutfits")
	}

	sameAgain := updated.Adding("outfit1.avatar")
	if len(sameAgain.WornOutfits) != 1 {
		t.Error("Adding same outfit twice should not increase count")
	}
}

func TestCategoryCache_Reset(t *testing.T) {
	cache := NewCategoryCache(5).
		Adding("outfit1.avatar").
		Adding("outfit2.avatar")

	reset := cache.Reset()
	if len(reset.WornOutfits) != 0 {
		t.Errorf("Reset WornOutfits length = %v, want 0", len(reset.WornOutfits))
	}
	if reset.TotalOutfits != 5 {
		t.Errorf("Reset TotalOutfits = %v, want 5", reset.TotalOutfits)
	}
}

func TestCategoryCache_RemainingOutfits(t *testing.T) {
	tests := []struct {
		name  string
		cache CategoryCache
		want  int
	}{
		{
			name:  "some remaining",
			cache: NewCategoryCache(5).Adding("outfit1.avatar"),
			want:  4,
		},
		{
			name:  "more worn than total",
			cache: CategoryCache{WornOutfits: map[string]bool{"a": true, "b": true}, TotalOutfits: 1},
			want:  0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.cache.RemainingOutfits(); got != tt.want {
				t.Errorf("RemainingOutfits() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestCategoryCache_RotationProgress(t *testing.T) {
	tests := []struct {
		name  string
		cache CategoryCache
		want  float64
	}{
		{
			name:  "half complete",
			cache: NewCategoryCache(4).Adding("outfit1.avatar").Adding("outfit2.avatar"),
			want:  0.5,
		},
		{
			name:  "zero outfits",
			cache: NewCategoryCache(0),
			want:  1.0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.cache.RotationProgress(); got != tt.want {
				t.Errorf("RotationProgress() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestCategoryCache_JSONMarshaling(t *testing.T) {
	cache := NewCategoryCache(5).Adding("outfit1.avatar")

	data, err := json.Marshal(cache)
	if err != nil {
		t.Fatalf("Marshal() error = %v", err)
	}

	var unmarshaled CategoryCache
	if err := json.Unmarshal(data, &unmarshaled); err != nil {
		t.Fatalf("Unmarshal() error = %v", err)
	}

	if unmarshaled.TotalOutfits != cache.TotalOutfits {
		t.Errorf("TotalOutfits = %v, want %v", unmarshaled.TotalOutfits, cache.TotalOutfits)
	}
	if len(unmarshaled.WornOutfits) != len(cache.WornOutfits) {
		t.Errorf("WornOutfits length = %v, want %v", len(unmarshaled.WornOutfits), len(cache.WornOutfits))
	}
}

func TestNewOutfitCache(t *testing.T) {
	cache := NewOutfitCache()

	if len(cache.Categories) != 0 {
		t.Errorf("Categories length = %v, want 0", len(cache.Categories))
	}
	if cache.Version != 1 {
		t.Errorf("Version = %v, want 1", cache.Version)
	}
}

func TestOutfitCache_Updating(t *testing.T) {
	cache := NewOutfitCache()
	catCache := NewCategoryCache(5)

	updated := cache.Updating("/path/to/casual", catCache)
	if len(updated.Categories) != 1 {
		t.Errorf("Categories length = %v, want 1", len(updated.Categories))
	}
	if updated.Categories["/path/to/casual"].TotalOutfits != 5 {
		t.Error("Category cache not stored correctly")
	}
}

func TestOutfitCache_Removing(t *testing.T) {
	cache := NewOutfitCache().
		Updating("/path/to/casual", NewCategoryCache(5)).
		Updating("/path/to/formal", NewCategoryCache(3))

	t.Run("remove existing", func(t *testing.T) {
		removed := cache.Removing("/path/to/casual")
		if len(removed.Categories) != 1 {
			t.Errorf("Categories length = %v, want 1", len(removed.Categories))
		}
		if _, ok := removed.Categories["/path/to/casual"]; ok {
			t.Error("Removed category should not exist")
		}
	})

	t.Run("remove non-existing", func(t *testing.T) {
		removed := cache.Removing("/path/to/nonexistent")
		if len(removed.Categories) != 2 {
			t.Errorf("Categories length = %v, want 2", len(removed.Categories))
		}
	})
}

func TestOutfitCache_Resetting(t *testing.T) {
	tests := []struct {
		name    string
		path    string
		wantNil bool
	}{
		{
			name:    "reset existing",
			path:    "/path/to/casual",
			wantNil: false,
		},
		{
			name:    "reset non-existing",
			path:    "/path/to/nonexistent",
			wantNil: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			catCache := NewCategoryCache(5).Adding("outfit1.avatar")
			cache := NewOutfitCache().Updating("/path/to/casual", catCache)

			reset := cache.Resetting(tt.path)
			if (reset == nil) != tt.wantNil {
				t.Errorf("Resetting() nil = %v, want %v", reset == nil, tt.wantNil)
				return
			}
			if !tt.wantNil && len(reset.Categories["/path/to/casual"].WornOutfits) != 0 {
				t.Error("Category cache should be reset")
			}
		})
	}
}

func TestOutfitCache_ResetAll(t *testing.T) {
	cache := NewOutfitCache().
		Updating("/path/to/casual", NewCategoryCache(5).Adding("outfit1.avatar")).
		Updating("/path/to/formal", NewCategoryCache(3).Adding("suit.avatar"))

	reset := cache.ResetAll()
	for _, catCache := range reset.Categories {
		if len(catCache.WornOutfits) != 0 {
			t.Error("All categories should be reset")
		}
	}
}

func TestOutfitCache_JSONMarshaling(t *testing.T) {
	cache := NewOutfitCache().
		Updating("/path/to/casual", NewCategoryCache(5))

	data, err := json.Marshal(cache)
	if err != nil {
		t.Fatalf("Marshal() error = %v", err)
	}

	var unmarshaled OutfitCache
	if err := json.Unmarshal(data, &unmarshaled); err != nil {
		t.Fatalf("Unmarshal() error = %v", err)
	}

	if len(unmarshaled.Categories) != len(cache.Categories) {
		t.Errorf("Categories length = %v, want %v", len(unmarshaled.Categories), len(cache.Categories))
	}
}
