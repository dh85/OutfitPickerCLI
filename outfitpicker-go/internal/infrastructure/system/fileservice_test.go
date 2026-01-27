package system

import (
	"errors"
	"os"
	"path/filepath"
	"testing"
)

type testConfig struct {
	Name  string `json:"name"`
	Value int    `json:"value"`
}

type mockDataManager struct {
	readFunc  func(path string) ([]byte, error)
	writeFunc func(path string, data []byte) error
}

func (m *mockDataManager) Read(path string) ([]byte, error) {
	return m.readFunc(path)
}

func (m *mockDataManager) Write(path string, data []byte) error {
	return m.writeFunc(path, data)
}

type mockDirectoryProvider struct {
	baseDirFunc func() (string, error)
}

func (m *mockDirectoryProvider) BaseDirectory() (string, error) {
	return m.baseDirFunc()
}

type mockFileManager struct {
	existsFunc func(path string) bool
	removeFunc func(path string) error
	mkdirFunc  func(path string) error
}

func (m *mockFileManager) Exists(path string) bool {
	return m.existsFunc(path)
}

func (m *mockFileManager) Remove(path string) error {
	return m.removeFunc(path)
}

func (m *mockFileManager) MkdirAll(path string) error {
	return m.mkdirFunc(path)
}

func newMockDirProvider(dir string, err error) *mockDirectoryProvider {
	return &mockDirectoryProvider{
		baseDirFunc: func() (string, error) {
			return dir, err
		},
	}
}

func newMockDataManager(readData string, readErr, writeErr error) *mockDataManager {
	return &mockDataManager{
		readFunc: func(path string) ([]byte, error) {
			if readErr != nil {
				return nil, readErr
			}
			return []byte(readData), nil
		},
		writeFunc: func(path string, data []byte) error {
			return writeErr
		},
	}
}

func newMockFileManager(exists bool, removeErr, mkdirErr error) *mockFileManager {
	return &mockFileManager{
		existsFunc: func(path string) bool {
			return exists
		},
		removeFunc: func(path string) error {
			return removeErr
		},
		mkdirFunc: func(path string) error {
			return mkdirErr
		},
	}
}

func TestFileService_FilePath(t *testing.T) {
	tests := []struct {
		name    string
		baseDir string
		baseErr error
		want    string
		wantErr bool
	}{
		{
			name:    "valid base directory",
			baseDir: "/home/user/.config",
			want:    "/home/user/.config/outfitpicker/test.json",
		},
		{
			name:    "directory provider error",
			baseErr: errors.New("no directory"),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fs := NewFileService[testConfig]("test.json",
				WithDirectoryProvider[testConfig](newMockDirProvider(tt.baseDir, tt.baseErr)))

			got, err := fs.FilePath()
			if (err != nil) != tt.wantErr {
				t.Errorf("FilePath() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && got != tt.want {
				t.Errorf("FilePath() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestFileService_Load(t *testing.T) {
	tests := []struct {
		name       string
		fileExists bool
		fileData   string
		readErr    error
		dirErr     error
		want       *testConfig
		wantErr    bool
	}{
		{
			name:       "file exists and valid",
			fileExists: true,
			fileData:   `{"name":"test","value":42}`,
			want:       &testConfig{Name: "test", Value: 42},
		},
		{
			name: "file does not exist",
		},
		{
			name:       "read error",
			fileExists: true,
			readErr:    errors.New("read failed"),
			wantErr:    true,
		},
		{
			name:       "invalid json",
			fileExists: true,
			fileData:   `{invalid}`,
			wantErr:    true,
		},
		{
			name:    "directory provider error",
			dirErr:  errors.New("dir error"),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fs := NewFileService[testConfig]("test.json",
				WithDirectoryProvider[testConfig](newMockDirProvider("/tmp", tt.dirErr)),
				WithDataManager[testConfig](newMockDataManager(tt.fileData, tt.readErr, nil)),
				WithFileManager[testConfig](newMockFileManager(tt.fileExists, nil, nil)))

			got, err := fs.Load()
			if (err != nil) != tt.wantErr {
				t.Errorf("Load() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr {
				if tt.want == nil && got != nil {
					t.Errorf("Load() = %v, want nil", got)
				}
				if tt.want != nil && (got == nil || got.Name != tt.want.Name || got.Value != tt.want.Value) {
					t.Errorf("Load() = %v, want %v", got, tt.want)
				}
			}
		})
	}
}

func TestFileService_Save(t *testing.T) {
	tests := []struct {
		name     string
		config   testConfig
		mkdirErr error
		writeErr error
		dirErr   error
		wantErr  bool
	}{
		{
			name:   "successful save",
			config: testConfig{Name: "test", Value: 42},
		},
		{
			name:     "mkdir error",
			config:   testConfig{Name: "test", Value: 42},
			mkdirErr: errors.New("mkdir failed"),
			wantErr:  true,
		},
		{
			name:     "write error",
			config:   testConfig{Name: "test", Value: 42},
			writeErr: errors.New("write failed"),
			wantErr:  true,
		},
		{
			name:    "directory provider error",
			config:  testConfig{Name: "test", Value: 42},
			dirErr:  errors.New("dir error"),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fs := NewFileService[testConfig]("test.json",
				WithDirectoryProvider[testConfig](newMockDirProvider("/tmp", tt.dirErr)),
				WithDataManager[testConfig](newMockDataManager("", nil, tt.writeErr)),
				WithFileManager[testConfig](newMockFileManager(false, nil, tt.mkdirErr)))

			err := fs.Save(tt.config)
			if (err != nil) != tt.wantErr {
				t.Errorf("Save() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestFileService_Delete(t *testing.T) {
	tests := []struct {
		name       string
		fileExists bool
		removeErr  error
		dirErr     error
		wantErr    bool
	}{
		{
			name:       "file exists and deleted",
			fileExists: true,
		},
		{
			name: "file does not exist",
		},
		{
			name:       "remove error",
			fileExists: true,
			removeErr:  errors.New("remove failed"),
			wantErr:    true,
		},
		{
			name:    "directory provider error",
			dirErr:  errors.New("dir error"),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fs := NewFileService[testConfig]("test.json",
				WithDirectoryProvider[testConfig](newMockDirProvider("/tmp", tt.dirErr)),
				WithFileManager[testConfig](newMockFileManager(tt.fileExists, tt.removeErr, nil)))

			err := fs.Delete()
			if (err != nil) != tt.wantErr {
				t.Errorf("Delete() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestDefaultDirectoryProvider(t *testing.T) {
	t.Run("uses XDG_CONFIG_HOME when set", func(t *testing.T) {
		os.Setenv("XDG_CONFIG_HOME", "/custom/config")
		defer os.Unsetenv("XDG_CONFIG_HOME")

		provider := NewDefaultDirectoryProvider()
		dir, err := provider.BaseDirectory()

		if err != nil {
			t.Errorf("BaseDirectory() error = %v", err)
		}
		if dir != "/custom/config" {
			t.Errorf("BaseDirectory() = %v, want /custom/config", dir)
		}
	})

	t.Run("uses user config dir when XDG not set", func(t *testing.T) {
		os.Unsetenv("XDG_CONFIG_HOME")

		provider := NewDefaultDirectoryProvider()
		dir, err := provider.BaseDirectory()

		if err != nil {
			t.Errorf("BaseDirectory() error = %v", err)
		}
		if dir == "" {
			t.Error("BaseDirectory() returned empty string")
		}
	})
}

func TestIntegration_FileService(t *testing.T) {
	tmpDir := t.TempDir()
	fs := NewFileService[testConfig]("test.json",
		WithDirectoryProvider[testConfig](newMockDirProvider(tmpDir, nil)))

	config := testConfig{Name: "integration", Value: 99}

	if err := fs.Save(config); err != nil {
		t.Fatalf("Save() error = %v", err)
	}

	loaded, err := fs.Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if loaded == nil || loaded.Name != config.Name || loaded.Value != config.Value {
		t.Errorf("Load() = %v, want %v", loaded, config)
	}

	if err := fs.Delete(); err != nil {
		t.Fatalf("Delete() error = %v", err)
	}

	loaded, err = fs.Load()
	if err != nil {
		t.Fatalf("Load() after delete error = %v", err)
	}
	if loaded != nil {
		t.Errorf("Load() after delete = %v, want nil", loaded)
	}

	path, _ := fs.FilePath()
	expectedPath := filepath.Join(tmpDir, "outfitpicker", "test.json")
	if path != expectedPath {
		t.Errorf("FilePath() = %v, want %v", path, expectedPath)
	}
}

type unmarshalableType struct {
	Ch chan int
}

func TestFileService_Save_MarshalError(t *testing.T) {
	fs := NewFileService[unmarshalableType]("test.json",
		WithDirectoryProvider[unmarshalableType](newMockDirProvider("/tmp", nil)),
		WithFileManager[unmarshalableType](newMockFileManager(false, nil, nil)))

	err := fs.Save(unmarshalableType{Ch: make(chan int)})
	if err == nil {
		t.Error("Save() expected error for unmarshalable type, got nil")
	}
}

func TestFileService_Save_WriteError(t *testing.T) {
	fs := NewFileService[testConfig]("test.json",
		WithDirectoryProvider[testConfig](newMockDirProvider("/tmp", nil)),
		WithDataManager[testConfig](newMockDataManager("", nil, errors.New("write failed"))),
		WithFileManager[testConfig](newMockFileManager(false, nil, nil)))

	err := fs.Save(testConfig{Name: "test", Value: 42})
	if err == nil {
		t.Error("Save() expected write error, got nil")
	}
}
