package entities

import (
	"encoding/json"
	"testing"
)

func TestNewConfig(t *testing.T) {
	tests := []struct {
		name    string
		root    string
		lang    *string
		wantErr bool
	}{
		{
			name:    "valid config",
			root:    "/home/user/outfits",
			lang:    stringPtr("en"),
			wantErr: false,
		},
		{
			name:    "valid config with nil language",
			root:    "/home/user/outfits",
			lang:    nil,
			wantErr: false,
		},
		{
			name:    "empty root",
			root:    "",
			wantErr: true,
		},
		{
			name:    "whitespace root",
			root:    "   ",
			wantErr: true,
		},
		{
			name:    "invalid path traversal",
			root:    "/home/../../../etc",
			wantErr: true,
		},
		{
			name:    "invalid language",
			root:    "/home/user/outfits",
			lang:    stringPtr("invalid"),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			config, err := NewConfig(tt.root, tt.lang, nil, nil, nil)
			if (err != nil) != tt.wantErr {
				t.Errorf("NewConfig() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr {
				if config.Root != tt.root {
					t.Errorf("Root = %v, want %v", config.Root, tt.root)
				}
				if tt.lang == nil && config.Language != "en" {
					t.Errorf("Language = %v, want en (default)", config.Language)
				}
			}
		})
	}
}

func TestConfig_WithExcludedCategories(t *testing.T) {
	excluded := map[string]bool{"formal": true, "winter": true}
	config, err := NewConfig("/home/user/outfits", nil, excluded, nil, nil)

	if err != nil {
		t.Fatalf("NewConfig() error = %v", err)
	}

	if len(config.ExcludedCategories) != 2 {
		t.Errorf("ExcludedCategories length = %v, want 2", len(config.ExcludedCategories))
	}
	if !config.ExcludedCategories["formal"] {
		t.Error("ExcludedCategories should contain 'formal'")
	}
}

func TestConfig_WithKnownCategories(t *testing.T) {
	known := map[string]bool{"casual": true, "formal": true}
	config, err := NewConfig("/home/user/outfits", nil, nil, known, nil)

	if err != nil {
		t.Fatalf("NewConfig() error = %v", err)
	}

	if len(config.KnownCategories) != 2 {
		t.Errorf("KnownCategories length = %v, want 2", len(config.KnownCategories))
	}
}

func TestConfig_WithKnownCategoryFiles(t *testing.T) {
	files := map[string]map[string]bool{
		"casual": {"outfit1.avatar": true, "outfit2.avatar": true},
	}
	config, err := NewConfig("/home/user/outfits", nil, nil, nil, files)

	if err != nil {
		t.Fatalf("NewConfig() error = %v", err)
	}

	if len(config.KnownCategoryFiles) != 1 {
		t.Errorf("KnownCategoryFiles length = %v, want 1", len(config.KnownCategoryFiles))
	}
	if len(config.KnownCategoryFiles["casual"]) != 2 {
		t.Errorf("KnownCategoryFiles[casual] length = %v, want 2", len(config.KnownCategoryFiles["casual"]))
	}
}

func TestConfig_JSONMarshaling(t *testing.T) {
	config, err := NewConfig("/home/user/outfits", stringPtr("es"), nil, nil, nil)
	if err != nil {
		t.Fatalf("NewConfig() error = %v", err)
	}

	data, err := json.Marshal(config)
	if err != nil {
		t.Fatalf("Marshal() error = %v", err)
	}

	var unmarshaled Config
	if err := json.Unmarshal(data, &unmarshaled); err != nil {
		t.Fatalf("Unmarshal() error = %v", err)
	}

	if unmarshaled.Root != config.Root {
		t.Errorf("Root = %v, want %v", unmarshaled.Root, config.Root)
	}
	if unmarshaled.Language != config.Language {
		t.Errorf("Language = %v, want %v", unmarshaled.Language, config.Language)
	}
}

func stringPtr(s string) *string {
	return &s
}
