package entities

import (
	"encoding/json"
	"testing"
)

func TestCategoryState_JSONMarshaling(t *testing.T) {
	tests := []struct {
		name  string
		state CategoryState
	}{
		{"has outfits", CategoryStateHasOutfits},
		{"empty", CategoryStateEmpty},
		{"no avatar files", CategoryStateNoAvatarFiles},
		{"user excluded", CategoryStateUserExcluded},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			data, err := json.Marshal(tt.state)
			if err != nil {
				t.Fatalf("Marshal() error = %v", err)
			}

			var unmarshaled CategoryState
			if err := json.Unmarshal(data, &unmarshaled); err != nil {
				t.Fatalf("Unmarshal() error = %v", err)
			}

			if unmarshaled != tt.state {
				t.Errorf("round-trip failed: got %v, want %v", unmarshaled, tt.state)
			}
		})
	}
}

func TestCategoryInfo_Creation(t *testing.T) {
	ref := NewCategoryReference("casual", "/home/user/outfits/casual")
	info := NewCategoryInfo(ref, CategoryStateHasOutfits, 5)

	if info.Category != ref {
		t.Errorf("Category = %v, want %v", info.Category, ref)
	}
	if info.State != CategoryStateHasOutfits {
		t.Errorf("State = %v, want %v", info.State, CategoryStateHasOutfits)
	}
	if info.OutfitCount != 5 {
		t.Errorf("OutfitCount = %v, want 5", info.OutfitCount)
	}
}

func TestCategoryInfo_JSONMarshaling(t *testing.T) {
	ref := NewCategoryReference("casual", "/home/user/outfits/casual")
	info := NewCategoryInfo(ref, CategoryStateHasOutfits, 5)

	data, err := json.Marshal(info)
	if err != nil {
		t.Fatalf("Marshal() error = %v", err)
	}

	var unmarshaled CategoryInfo
	if err := json.Unmarshal(data, &unmarshaled); err != nil {
		t.Fatalf("Unmarshal() error = %v", err)
	}

	if unmarshaled != info {
		t.Errorf("round-trip failed: got %v, want %v", unmarshaled, info)
	}
}
