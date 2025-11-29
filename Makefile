# Makefile for Buatsaver
# Provides convenient commands for building, testing, and packaging

.PHONY: all build clean test dmg

# Default target
all: build

# Build the application
build:
	@chmod +x Scripts/build.sh
	@./Scripts/build.sh

# Create DMG package
dmg: build
	@chmod +x Scripts/create_dmg.sh
	@./Scripts/create_dmg.sh

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build/
	@rm -f Buatsaver-*.dmg
	@echo "✅ Clean complete"

# Run basic tests (placeholder for future testing)
test: build
	@echo "🧪 Running tests..."
	@# Add testing commands here when tests are implemented
	@echo "✅ Tests completed"
