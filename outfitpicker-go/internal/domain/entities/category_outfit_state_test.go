package entities

import "testing"

func TestNewCategoryOutfitState(t *testing.T) {
	category := NewCategoryReference("casual", "/path/to/casual")
	all := []OutfitReference{
		NewOutfitReference("outfit1.avatar", category),
		NewOutfitReference("outfit2.avatar", category),
		NewOutfitReference("outfit3.avatar", category),
	}
	available := all[:2]
	worn := all[2:]

	state := NewCategoryOutfitState(category, all, available, worn)

	if state.Category != category {
		t.Errorf("Category = %v, want %v", state.Category, category)
	}
	if len(state.AllOutfits) != 3 {
		t.Errorf("AllOutfits length = %v, want 3", len(state.AllOutfits))
	}
	if len(state.AvailableOutfits) != 2 {
		t.Errorf("AvailableOutfits length = %v, want 2", len(state.AvailableOutfits))
	}
	if len(state.WornOutfits) != 1 {
		t.Errorf("WornOutfits length = %v, want 1", len(state.WornOutfits))
	}
}

func TestCategoryOutfitState_Counts(t *testing.T) {
	category := NewCategoryReference("casual", "/path/to/casual")
	all := []OutfitReference{
		NewOutfitReference("outfit1.avatar", category),
		NewOutfitReference("outfit2.avatar", category),
	}
	
	state := NewCategoryOutfitState(category, all, all[:1], all[1:])

	if got := state.TotalCount(); got != 2 {
		t.Errorf("TotalCount() = %v, want 2", got)
	}
	if got := state.AvailableCount(); got != 1 {
		t.Errorf("AvailableCount() = %v, want 1", got)
	}
	if got := state.WornCount(); got != 1 {
		t.Errorf("WornCount() = %v, want 1", got)
	}
}

func TestCategoryOutfitState_ProgressPercentage(t *testing.T) {
	category := NewCategoryReference("casual", "/path/to/casual")
	
	tests := []struct {
		name       string
		totalCount int
		wornCount  int
		want       float64
	}{
		{"30% worn", 10, 3, 0.3},
		{"50% worn", 10, 5, 0.5},
		{"100% worn", 10, 10, 1.0},
		{"zero total", 0, 0, 0.0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			all := make([]OutfitReference, tt.totalCount)
			for i := range all {
				all[i] = NewOutfitReference("outfit.avatar", category)
			}
			state := NewCategoryOutfitState(category, all, all[tt.wornCount:], all[:tt.wornCount])
			
			if got := state.ProgressPercentage(); got != tt.want {
				t.Errorf("ProgressPercentage() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestCategoryOutfitState_IsRotationComplete(t *testing.T) {
	category := NewCategoryReference("casual", "/path/to/casual")
	all := make([]OutfitReference, 5)
	for i := range all {
		all[i] = NewOutfitReference("outfit.avatar", category)
	}

	tests := []struct {
		name      string
		wornCount int
		want      bool
	}{
		{"not complete", 3, false},
		{"complete", 5, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			state := NewCategoryOutfitState(category, all, all[tt.wornCount:], all[:tt.wornCount])
			
			if got := state.IsRotationComplete(); got != tt.want {
				t.Errorf("IsRotationComplete() = %v, want %v", got, tt.want)
			}
		})
	}
}
