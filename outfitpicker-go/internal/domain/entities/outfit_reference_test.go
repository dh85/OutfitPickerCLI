package entities

import (
	"encoding/json"
	"path/filepath"
	"testing"
)

func TestNewOutfitReference(t *testing.T) {
	category := NewCategoryReference("casual", "/home/user/outfits/casual")
	ref := NewOutfitReference("jeans-tshirt.avatar", category)

	if ref.FileName != "jeans-tshirt.avatar" {
		t.Errorf("FileName = %v, want jeans-tshirt.avatar", ref.FileName)
	}
	if ref.Category != category {
		t.Errorf("Category = %v, want %v", ref.Category, category)
	}
}

func TestOutfitReference_FilePath(t *testing.T) {
	category := NewCategoryReference("casual", "/home/user/outfits/casual")
	ref := NewOutfitReference("jeans-tshirt.avatar", category)

	want := filepath.Join("/home/user/outfits/casual", "jeans-tshirt.avatar")
	if got := ref.FilePath(); got != want {
		t.Errorf("FilePath() = %v, want %v", got, want)
	}
}

func TestOutfitReference_String(t *testing.T) {
	category := NewCategoryReference("casual", "/home/user/outfits/casual")
	ref := NewOutfitReference("jeans-tshirt.avatar", category)

	want := "jeans-tshirt.avatar in casual"
	if got := ref.String(); got != want {
		t.Errorf("String() = %v, want %v", got, want)
	}
}

func TestOutfitReference_JSONMarshaling(t *testing.T) {
	category := NewCategoryReference("casual", "/home/user/outfits/casual")
	ref := NewOutfitReference("jeans-tshirt.avatar", category)

	data, err := json.Marshal(ref)
	if err != nil {
		t.Fatalf("Marshal() error = %v", err)
	}

	var unmarshaled OutfitReference
	if err := json.Unmarshal(data, &unmarshaled); err != nil {
		t.Fatalf("Unmarshal() error = %v", err)
	}

	if unmarshaled != ref {
		t.Errorf("round-trip failed: got %v, want %v", unmarshaled, ref)
	}
}
