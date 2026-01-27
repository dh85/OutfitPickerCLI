package entities

// CategoryReference identifies a category directory containing outfit files.
type CategoryReference struct {
	Name string `json:"name"`
	Path string `json:"path"`
}

// NewCategoryReference creates a new category reference.
func NewCategoryReference(name, path string) CategoryReference {
	return CategoryReference{Name: name, Path: path}
}

func (c CategoryReference) String() string {
	return c.Name
}
