# OutfitPicker - Go Implementation

A Go port of the OutfitPickerCLI Swift application using Test-Driven Development.

## Project Structure

```
outfitpicker-go/
├── cmd/outfitpicker/          # Application entry point
├── internal/                   # Private application code
│   ├── domain/                # Business logic layer
│   │   ├── entities/          # Core data structures
│   │   ├── errors/            # Custom error types
│   │   ├── interfaces/        # Port definitions
│   │   ├── logic/             # Business rules
│   │   └── validation/        # Input validators
│   ├── application/           # Use cases
│   │   └── usecases/          # Application-specific logic
│   ├── infrastructure/        # External concerns
│   │   ├── configuration/     # Config management
│   │   ├── persistence/       # Data storage
│   │   └── system/            # File system operations
│   └── cli/                   # CLI interface
│       ├── config/            # CLI configuration
│       ├── menu/              # Menu system
│       ├── models/            # CLI models
│       ├── services/          # CLI services
│       └── ui/                # User interface
└── pkg/testhelpers/           # Shared test utilities
```

## Development

```bash
# Run tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Build
go build -o bin/outfitpicker ./cmd/outfitpicker

# Run
./bin/outfitpicker
```

## TDD Progress

- [x] Phase 1: Foundation & Infrastructure
  - [x] File System Abstractions (100% coverage)
    - FileService with generic type support
    - DataManager, DirectoryProvider, FileManager interfaces
    - XDG_CONFIG_HOME support
  - [x] Domain Entities (100% coverage)
    - CategoryReference
    - FileEntry
    - CategoryState & CategoryInfo
    - OutfitReference
    - CategoryCache & OutfitCache
    - SelectionTarget & RotationProgress
    - CategoryOutfitState
    - Config (with validation)
    - ConfigBuilder (fluent API)
  - [x] Error Handling (100% coverage)
    - Sentinel errors for all error types
    - Custom errors (InvalidInputError, RotationCompletedError)
    - MapError for error conversion
- [x] Phase 2: Business Logic & Validation
  - [x] Validators (100% coverage)
    - PathValidator (security checks, traversal, restricted paths)
    - LanguageValidator (supported language codes)
  - [x] Business Rules (100% coverage)
    - File validation (outfit files, categories)
    - Rotation logic (progress, completion, reset)
    - Outfit filtering
- [ ] Phase 3: Services & Repositories
- [ ] Phase 4: Application Layer
- [ ] Phase 5: CLI Layer
- [ ] Phase 6: Testing Infrastructure
