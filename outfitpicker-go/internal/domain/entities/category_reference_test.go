package entities

import (
	"encoding/json"
	"testing"
)

func TestNewCategoryReference(t *testing.T) {
	ref := NewCategoryReference("casual", "/home/user/outfits/casual")
	if ref.Name != "casual" {
		t.Errorf("Name = %v, want casual", ref.Name)
	}
	if ref.Path != "/home/user/outfits/casual" {
		t.Errorf("Path = %v, want /home/user/outfits/casual", ref.Path)
	}
}

func TestCategoryReference_JSONMarshaling(t *testing.T) {
	tests := []struct {
		name string
		ref  CategoryReference
	}{
		{
			name: "basic category",
			ref:  CategoryReference{Name: "casual", Path: "/home/user/outfits/casual"},
		},
		{
			name: "category with spaces",
			ref:  CategoryReference{Name: "work attire", Path: "/home/user/outfits/work attire"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			data, err := json.Marshal(tt.ref)
			if err != nil {
				t.Fatalf("Marshal() error = %v", err)
			}

			var unmarshaled CategoryReference
			if err := json.Unmarshal(data, &unmarshaled); err != nil {
				t.Fatalf("Unmarshal() error = %v", err)
			}

			if unmarshaled != tt.ref {
				t.Errorf("round-trip failed: got %v, want %v", unmarshaled, tt.ref)
			}
		})
	}
}

func TestCategoryReference_String(t *testing.T) {
	ref := CategoryReference{Name: "casual", Path: "/home/user/outfits/casual"}
	if got := ref.String(); got != "casual" {
		t.Errorf("String() = %v, want casual", got)
	}
}
