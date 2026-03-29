# List available recipes
default:
	@just --list

# Build the project
build:
	xcodebuild -scheme Beans -destination 'platform=macOS' build | xcbeautify

# Clean Xcode derived data for this project
clean:
	xcodebuild -scheme Beans -destination 'platform=macOS' clean

# Archive, notarize, and install to /Applications
install:
	#!/bin/bash
	set -euo pipefail
	BUILD_DIR="$(mktemp -d)"
	trap 'rm -rf "$BUILD_DIR"' EXIT
	echo "Archiving..."
	xcodebuild archive \
		-scheme Beans \
		-destination 'platform=macOS' \
		-archivePath "$BUILD_DIR/Beans.xcarchive" \
		| xcbeautify
	echo "Exporting and notarizing (this may take a few minutes)..."
	xcodebuild -exportArchive \
		-archivePath "$BUILD_DIR/Beans.xcarchive" \
		-exportOptionsPlist ExportOptions.plist \
		-exportPath "$BUILD_DIR/export" \
		| xcbeautify
	echo "Installing to /Applications..."
	rm -rf /Applications/Beans.app
	cp -R "$BUILD_DIR/export/Beans.app" /Applications/Beans.app
	open /Applications/Beans.app
	echo "Done. Beans.app installed and launched."

# Format code with SwiftFormat
format:
	mint run swiftformat .

# Run SwiftLint
lint:
	mint run swiftlint

# Show outdated Swift packages
outdated:
	mint run swift-outdated --ignore-prerelease

# Place pre-commit hook locally
pre-commit:
	cp .scripts/pre-commit .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit

# Run tests
test:
	xcodebuild -scheme Beans -destination 'platform=macOS' test | xcbeautify

# Install developer tools
tools:
	curl -o ./.swiftformat https://raw.githubusercontent.com/brzzdev/Configs/main/Configs/swiftformat
	which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew bundle --no-lock install
	mint bootstrap
	just pre-commit
