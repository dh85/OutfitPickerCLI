.PHONY: test build clean run coverage

test:
	go test ./...

coverage:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

build:
	go build -o bin/outfitpicker ./cmd/outfitpicker

clean:
	rm -rf bin/ coverage.out coverage.html

run: build
	./bin/outfitpicker
