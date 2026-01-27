package system

import (
	"encoding/json"
	"path/filepath"
)

const appName = "outfitpicker"

type DataManager interface {
	Read(path string) ([]byte, error)
	Write(path string, data []byte) error
}

type DirectoryProvider interface {
	BaseDirectory() (string, error)
}

type FileManager interface {
	Exists(path string) bool
	Remove(path string) error
	MkdirAll(path string) error
}

type FileService[T any] struct {
	fileName          string
	dataManager       DataManager
	directoryProvider DirectoryProvider
	fileManager       FileManager
}

type FileServiceOption[T any] func(*FileService[T])

func WithDataManager[T any](dm DataManager) FileServiceOption[T] {
	return func(fs *FileService[T]) {
		fs.dataManager = dm
	}
}

func WithDirectoryProvider[T any](dp DirectoryProvider) FileServiceOption[T] {
	return func(fs *FileService[T]) {
		fs.directoryProvider = dp
	}
}

func WithFileManager[T any](fm FileManager) FileServiceOption[T] {
	return func(fs *FileService[T]) {
		fs.fileManager = fm
	}
}

func NewFileService[T any](fileName string, opts ...FileServiceOption[T]) *FileService[T] {
	fs := &FileService[T]{
		fileName:          fileName,
		dataManager:       &defaultDataManager{},
		directoryProvider: NewDefaultDirectoryProvider(),
		fileManager:       &defaultFileManager{},
	}

	for _, opt := range opts {
		opt(fs)
	}

	return fs
}

func (fs *FileService[T]) FilePath() (string, error) {
	baseDir, err := fs.directoryProvider.BaseDirectory()
	if err != nil {
		return "", err
	}
	return filepath.Join(baseDir, appName, fs.fileName), nil
}

func (fs *FileService[T]) Load() (*T, error) {
	path, err := fs.FilePath()
	if err != nil {
		return nil, err
	}

	if !fs.fileManager.Exists(path) {
		return nil, nil
	}

	data, err := fs.dataManager.Read(path)
	if err != nil {
		return nil, err
	}

	var result T
	if err := json.Unmarshal(data, &result); err != nil {
		return nil, err
	}

	return &result, nil
}

func (fs *FileService[T]) Save(obj T) error {
	path, err := fs.FilePath()
	if err != nil {
		return err
	}

	if err := fs.fileManager.MkdirAll(filepath.Dir(path)); err != nil {
		return err
	}

	data, err := json.MarshalIndent(obj, "", "  ")
	if err != nil {
		return err
	}

	return fs.dataManager.Write(path, data)
}

func (fs *FileService[T]) Delete() error {
	path, err := fs.FilePath()
	if err != nil {
		return err
	}

	if !fs.fileManager.Exists(path) {
		return nil
	}

	return fs.fileManager.Remove(path)
}
