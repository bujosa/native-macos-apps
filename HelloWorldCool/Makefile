APP_NAME = HelloWorldCool
BUILD_DIR = .build_output

# 1. Generate the Xcode project from Project.swift
generate:
	tuist generate --no-open

# 2. Build the app (Debug)
build: generate
	xcodebuild \
		-scheme $(APP_NAME) \
		-destination 'platform=macOS' \
		-derivedDataPath $(BUILD_DIR) \
		build

# 3. Build and run
run: build
	@echo "Opening $(APP_NAME)..."
	open "$(BUILD_DIR)/Build/Products/Debug/$(APP_NAME).app"

# 4. Build in Release mode
release: generate
	xcodebuild \
		-scheme $(APP_NAME) \
		-destination 'platform=macOS' \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		build

# 5. Clean everything
clean:
	rm -rf *.xcodeproj *.xcworkspace $(BUILD_DIR) Derived/
	tuist clean

# 6. Edit the manifest with Xcode autocomplete
edit:
	tuist edit
