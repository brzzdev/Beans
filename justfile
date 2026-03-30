swiftformat_base := "/tmp/swiftformat-base"

# List available recipes
default:
	@just --list

# Build the project
build:
	xcodebuild -scheme Beans -destination 'platform=macOS' build | xcbeautify

# Clean Xcode derived data for this project
clean:
	xcodebuild -scheme Beans -destination 'platform=macOS' clean

[private]
fetch-swiftformat-config:
	curl -sL https://raw.githubusercontent.com/brzzdev/Configs/main/Configs/swiftformat -o {{ swiftformat_base }}

# Format code with SwiftFormat
format: fetch-swiftformat-config
	mint run swiftformat . --base-config {{ swiftformat_base }}

[private]
format-staged: fetch-swiftformat-config
	./.git-format-staged --formatter "$(mint which swiftformat 2>/dev/null | tail -1) stdin --stdinpath '{}' --base-config {{ swiftformat_base }}" "*.swift"

# Place pre-commit hook locally
pre-commit:
	cp .scripts/pre-commit .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit

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

# Run SwiftLint
lint:
	swiftlint

# Run tests
test:
	xcodebuild -scheme Beans -destination 'platform=macOS' test | xcbeautify
