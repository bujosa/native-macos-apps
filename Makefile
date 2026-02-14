APP_NAME ?= HelloWorldCool
APP_DIR = $(APP_NAME)
BUILD_DIR = $(APP_DIR)/.build_output
OUT_DIR = executables

# 1. Generate the Xcode project from Project.swift
generate:
	cd $(APP_DIR) && tuist generate --no-open

# 2. Build the app (Debug)
build: generate
	xcodebuild \
		-scheme $(APP_NAME) \
		-destination 'platform=macOS' \
		-derivedDataPath $(BUILD_DIR) \
		-project $(APP_DIR)/$(APP_NAME).xcodeproj \
		build

# 3. Build and run
run: build
	@echo "Opening $(APP_NAME)..."
	open "$(BUILD_DIR)/Build/Products/Debug/$(APP_NAME).app"

# 4. Build in Release mode and generate .dmg installer
release: generate
	xcodebuild \
		-scheme $(APP_NAME) \
		-destination 'platform=macOS' \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		-project $(APP_DIR)/$(APP_NAME).xcodeproj \
		build
	@echo "Creating $(APP_NAME).dmg..."
	@mkdir -p $(OUT_DIR)
	@rm -rf .dmg_staging $(OUT_DIR)/$(APP_NAME).dmg
	@mkdir -p .dmg_staging
	@cp -r $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app .dmg_staging/
	@ln -s /Applications .dmg_staging/Applications
	@hdiutil create -volname "$(APP_NAME)" -srcfolder .dmg_staging -ov -format UDZO $(OUT_DIR)/$(APP_NAME).dmg
	@rm -rf .dmg_staging
	@echo "$(OUT_DIR)/$(APP_NAME).dmg created successfully"

# 5. Clean everything
clean:
	cd $(APP_DIR) && rm -rf *.xcodeproj *.xcworkspace .build_output Derived/
	cd $(APP_DIR) && tuist clean
	rm -rf .dmg_staging $(OUT_DIR)/$(APP_NAME).dmg

# 6. Edit the manifest with Xcode autocomplete
edit:
	cd $(APP_DIR) && tuist edit
