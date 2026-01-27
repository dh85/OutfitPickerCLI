package entities

import "path/filepath"

// FileEntry represents an outfit file with its filesystem context.
type FileEntry struct {
	filePath     string
	categoryPath string
	FileName     string
}

// NewFileEntry creates a new file entry from a file path.
func NewFileEntry(filePath string) FileEntry {
	categoryPath := filepath.Dir(filePath)
	return FileEntry{
		filePath:     filePath,
		categoryPath: categoryPath,
		FileName:     filepath.Base(filePath),
	}
}

// CategoryPath returns the directory path containing this file.
func (f FileEntry) CategoryPath() string {
	return f.categoryPath
}

// CategoryName returns the name of the category directory.
func (f FileEntry) CategoryName() string {
	return filepath.Base(f.categoryPath)
}
