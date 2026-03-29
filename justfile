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
