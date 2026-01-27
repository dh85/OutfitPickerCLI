package entities

import (
	"encoding/json"
	"testing"
)

func TestSelectionTarget_JSONMarshaling(t *testing.T) {
	category := NewCategoryReference("casual", "/path/to/casual")
	
	tests := []struct {
		name   string
		target SelectionTarget
	}{
		{"single category", SelectionTargetCategory{Category: category}},
		{"all categories", SelectionTargetAllCategories{}},
		{"multiple categories", SelectionTargetCategories{Categories: []CategoryReference{category}}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			data, err := json.Marshal(tt.target)
			if err != nil {
				t.Fatalf("Marshal() error = %v", err)
			}

			var unmarshaled map[string]interface{}
			if err := json.Unmarshal(data, &unmarshaled); err != nil {
				t.Fatalf("Unmarshal() error = %v", err)
			}
		})
	}
}

func TestNewRotationProgress(t *testing.T) {
	category := NewCategoryReference("casual", "/path/to/casual")
	progress := NewRotationProgress(category, 3, 10)

	if progress.Category != category {
		t.Errorf("Category = %v, want %v", progress.Category, category)
	}
	if progress.WornCount != 3 {
		t.Errorf("WornCount = %v, want 3", progress.WornCount)
	}
	if progress.TotalOutfitCount != 10 {
		t.Errorf("TotalOutfitCount = %v, want 10", progress.TotalOutfitCount)
	}
}

func TestRotationProgress_Progress(t *testing.T) {
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
			category := NewCategoryReference("test", "/path")
			progress := NewRotationProgress(category, tt.wornCount, tt.totalCount)
			
			if got := progress.Progress(); got != tt.want {
				t.Errorf("Progress() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestRotationProgress_IsComplete(t *testing.T) {
	category := NewCategoryReference("test", "/path")
	
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
			progress := NewRotationProgress(category, tt.wornCount, tt.totalCount)
			
			if got := progress.IsComplete(); got != tt.want {
				t.Errorf("IsComplete() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestRotationProgress_AvailableCount(t *testing.T) {
	category := NewCategoryReference("test", "/path")
	
	tests := []struct {
		name       string
		wornCount  int
		totalCount int
		want       int
	}{
		{"some available", 3, 10, 7},
		{"all available when complete", 10, 10, 10},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			progress := NewRotationProgress(category, tt.wornCount, tt.totalCount)
			
			if got := progress.AvailableCount(); got != tt.want {
				t.Errorf("AvailableCount() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestRotationProgress_JSONMarshaling(t *testing.T) {
	category := NewCategoryReference("casual", "/path/to/casual")
	progress := NewRotationProgress(category, 3, 10)

	data, err := json.Marshal(progress)
	if err != nil {
		t.Fatalf("Marshal() error = %v", err)
	}

	var unmarshaled RotationProgress
	if err := json.Unmarshal(data, &unmarshaled); err != nil {
		t.Fatalf("Unmarshal() error = %v", err)
	}

	if unmarshaled != progress {
		t.Errorf("round-trip failed: got %v, want %v", unmarshaled, progress)
	}
}
