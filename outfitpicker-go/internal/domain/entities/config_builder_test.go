package entities

import "testing"

func TestConfigBuilder_Basic(t *testing.T) {
	builder := NewConfigBuilder()
	config, err := builder.
		RootDirectory("/home/user/outfits").
		Build()

	if err != nil {
		t.Fatalf("Build() error = %v", err)
	}
	if config.Root != "/home/user/outfits" {
		t.Errorf("Root = %v, want /home/user/outfits", config.Root)
	}
	if config.Language != DefaultLanguage {
		t.Errorf("Language = %v, want %v", config.Language, DefaultLanguage)
	}
}

func TestConfigBuilder_WithLanguage(t *testing.T) {
	builder := NewConfigBuilder()
	config, err := builder.
		RootDirectory("/home/user/outfits").
		Language("es").
		Build()

	if err != nil {
		t.Fatalf("Build() error = %v", err)
	}
	if config.Language != "es" {
		t.Errorf("Language = %v, want es", config.Language)
	}
}

func TestConfigBuilder_ExcludeCategories(t *testing.T) {
	builder := NewConfigBuilder()
	config, err := builder.
		RootDirectory("/home/user/outfits").
		Exclude("formal", "winter").
		Build()

	if err != nil {
		t.Fatalf("Build() error = %v", err)
	}
	if !config.ExcludedCategories["formal"] {
		t.Error("ExcludedCategories should contain 'formal'")
	}
	if !config.ExcludedCategories["winter"] {
		t.Error("ExcludedCategories should contain 'winter'")
	}
}

func TestConfigBuilder_ExcludeCategory(t *testing.T) {
	builder := NewConfigBuilder()
	config, err := builder.
		RootDirectory("/home/user/outfits").
		ExcludeCategory("formal").
		Build()

	if err != nil {
		t.Fatalf("Build() error = %v", err)
	}
	if !config.ExcludedCategories["formal"] {
		t.Error("ExcludedCategories should contain 'formal'")
	}
}

func TestConfigBuilder_IncludeCategories(t *testing.T) {
	builder := NewConfigBuilder()
	config, err := builder.
		RootDirectory("/home/user/outfits").
		Include("casual", "formal").
		Build()

	if err != nil {
		t.Fatalf("Build() error = %v", err)
	}
	if !config.KnownCategories["casual"] {
		t.Error("KnownCategories should contain 'casual'")
	}
	if !config.KnownCategories["formal"] {
		t.Error("KnownCategories should contain 'formal'")
	}
}

func TestConfigBuilder_IncludeCategory(t *testing.T) {
	builder := NewConfigBuilder()
	config, err := builder.
		RootDirectory("/home/user/outfits").
		IncludeCategory("casual").
		Build()

	if err != nil {
		t.Fatalf("Build() error = %v", err)
	}
	if !config.KnownCategories["casual"] {
		t.Error("KnownCategories should contain 'casual'")
	}
}

func TestConfigBuilder_NoRootError(t *testing.T) {
	builder := NewConfigBuilder()
	_, err := builder.Build()

	if err == nil {
		t.Error("Build() should error when root directory not set")
	}
}

func TestConfigBuilder_InvalidRoot(t *testing.T) {
	builder := NewConfigBuilder()
	_, err := builder.
		RootDirectory("").
		Build()

	if err == nil {
		t.Error("Build() should error with empty root")
	}
}

func TestConfigBuilder_InvalidLanguage(t *testing.T) {
	builder := NewConfigBuilder()
	_, err := builder.
		RootDirectory("/home/user/outfits").
		Language("invalid").
		Build()

	if err == nil {
		t.Error("Build() should error with invalid language")
	}
}

func TestConfigBuilder_Chaining(t *testing.T) {
	builder := NewConfigBuilder()
	config, err := builder.
		RootDirectory("/home/user/outfits").
		Language("fr").
		Exclude("formal", "winter").
		Include("casual", "sport").
		ExcludeCategory("business").
		IncludeCategory("weekend").
		Build()

	if err != nil {
		t.Fatalf("Build() error = %v", err)
	}

	if config.Root != "/home/user/outfits" {
		t.Errorf("Root = %v, want /home/user/outfits", config.Root)
	}
	if config.Language != "fr" {
		t.Errorf("Language = %v, want fr", config.Language)
	}
	if len(config.ExcludedCategories) != 3 {
		t.Errorf("ExcludedCategories length = %v, want 3", len(config.ExcludedCategories))
	}
	if len(config.KnownCategories) != 3 {
		t.Errorf("KnownCategories length = %v, want 3", len(config.KnownCategories))
	}
}
