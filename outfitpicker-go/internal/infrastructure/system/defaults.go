package system

import "os"

type defaultDataManager struct{}

func (d *defaultDataManager) Read(path string) ([]byte, error) {
	return os.ReadFile(path)
}

func (d *defaultDataManager) Write(path string, data []byte) error {
	return os.WriteFile(path, data, 0644)
}

type defaultDirectoryProvider struct{}

func NewDefaultDirectoryProvider() DirectoryProvider {
	return &defaultDirectoryProvider{}
}

func (d *defaultDirectoryProvider) BaseDirectory() (string, error) {
	if xdg := os.Getenv("XDG_CONFIG_HOME"); xdg != "" {
		return xdg, nil
	}
	return os.UserConfigDir()
}

type defaultFileManager struct{}

func (d *defaultFileManager) Exists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func (d *defaultFileManager) Remove(path string) error {
	return os.Remove(path)
}

func (d *defaultFileManager) MkdirAll(path string) error {
	return os.MkdirAll(path, 0700)
}
