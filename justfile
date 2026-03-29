# List available recipes
default:
	@just --list

# Build the project
build:
	xcodebuild -scheme Beans -destination 'platform=macOS' build | xcbeautify

# Clean Xcode derived data for this project
clean:
	xcodebuild -scheme Beans -destination 'platform=macOS' clean

# Format code with SwiftFormat
format:
	swiftformat .

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
