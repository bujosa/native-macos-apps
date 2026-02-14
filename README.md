# Building Native macOS Apps "Headless" (No Xcode GUI)

A corrected and verified guide for building high-performance native macOS applications using Swift and SwiftUI, with a workflow centered on **Cursor/VS Code** and the **Terminal**.

We treat the Xcode project infrastructure as code, avoiding the heavy `.xcodeproj` GUI entirely.

---

## 1. Philosophy

- **Editor:** Cursor (or VS Code)
- **Project Manager:** [Tuist](https://tuist.io/) — generates Xcode projects from Swift code
- **Build System:** `xcodebuild` (via Terminal/Makefile)
- **UI Framework:** SwiftUI

---

## 2. Prerequisites

You need **full Xcode** installed (not just Command Line Tools), since `xcodebuild` requires the complete macOS SDK to compile SwiftUI apps.

```bash
# Verify Xcode is installed and selected
xcode-select -p
# Should show something like: /Applications/Xcode.app/Contents/Developer

# If it points to CommandLineTools, switch it:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Accept the Xcode license (required first time)
sudo xcodebuild -license accept
```

---

## 3. Install Tuist

The currently recommended installation method is through **Mise** (version manager). The old `curl | bash` method no longer works.

```bash
# Option A: Install Mise first, then Tuist (RECOMMENDED)
brew install mise

# Add Mise to your shell (if using zsh)
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc

# Install Tuist
mise install tuist
mise use --global tuist@latest

# Verify
tuist version
```

```bash
# Option B: Install Tuist directly with Homebrew (simpler, less version control)
brew install tuist

# Verify
tuist version
```

---

## 4. Initialize the Project

```bash
mkdir MyLocalTool
cd MyLocalTool

# Initialize a project with Tuist
tuist init --platform macos --name MyLocalTool
```

This generates a structure like:

```
MyLocalTool/
├── Project.swift          # Project manifest
├── MyLocalTool/
│   ├── Sources/           # Your Swift code
│   └── Resources/         # Assets, etc.
├── Tuist/
│   └── Config.swift       # Tuist configuration
└── Package.swift          # SPM dependencies (if any)
```

> **Note:** If `tuist init` doesn't support `--platform macos` in your version, create the structure manually (see Step 6).

---

## 5. Project Configuration (Project.swift)

### Disabling the App Sandbox Correctly

The App Sandbox is controlled via an `.entitlements` file, **NOT** from the `infoPlist`. The original guide used `"App-Sandbox": false` in the Info.plist, which has no effect whatsoever.

**Step 5a:** Create the entitlements file at `MyLocalTool/MyLocalTool.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Do NOT include com.apple.security.app-sandbox = true -->
    <!-- By omitting it, the app is NOT sandboxed and can execute system commands -->
</dict>
</plist>
```

> **Important:** To disable the sandbox, simply **don't include** the `com.apple.security.app-sandbox` key, or set it to `false`. An empty dict means no sandbox.

**Step 5b:** Edit `Project.swift`:

```swift
import ProjectDescription

let project = Project(
    name: "MyLocalTool",
    targets: [
        .target(
            name: "MyLocalTool",
            destinations: .macOS,
            product: .app,
            bundleId: "com.local.mytool",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "MyLocalTool",
            ]),
            sources: ["MyLocalTool/Sources/**"],
            resources: ["MyLocalTool/Resources/**"],
            entitlements: .file(path: "MyLocalTool/MyLocalTool.entitlements"),
            dependencies: []
        )
    ]
)
```

Key changes from the original guide:

- Uses `entitlements: .file(path:)` to reference the `.entitlements` file
- Removed the fake `infoPlist` keys (`"App-Sandbox"` doesn't exist as an Info.plist key)
- Uses the current Tuist API with `.target()` and `destinations: .macOS`

---

## 6. Create the File Structure

Create the required directories and files:

```bash
# Create directories
mkdir -p MyLocalTool/Sources
mkdir -p MyLocalTool/Resources

# Create the entitlements file
cat > MyLocalTool/MyLocalTool.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
EOF
```

---

## 7. The Code (SwiftUI + Shell Execution)

### `MyLocalTool/Sources/MyLocalToolApp.swift`

```swift
import SwiftUI

@main
struct MyLocalToolApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### `MyLocalTool/Sources/ContentView.swift`

The corrected version runs commands **asynchronously** so the UI doesn't freeze:

```swift
import SwiftUI
import Foundation

struct ContentView: View {
    @State private var output: String = "Ready. Press a button to run a command."
    @State private var isRunning: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Local Ops Center")
                .font(.title2.bold())

            HStack(spacing: 12) {
                Button("Docker PS") {
                    runCommand(executable: "/usr/local/bin/docker", args: ["ps"])
                }
                .disabled(isRunning)

                Button("Git Status") {
                    runCommand(executable: "/usr/bin/git", args: ["status"])
                }
                .disabled(isRunning)

                Button("List Files") {
                    runCommand(executable: "/bin/ls", args: ["-la", NSHomeDirectory()])
                }
                .disabled(isRunning)
            }

            if isRunning {
                ProgressView("Running...")
            }

            ScrollView {
                Text(output)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }

    /// Runs a system command asynchronously (does not block the UI)
    func runCommand(executable: String, args: [String]) {
        isRunning = true
        output = "Running: \(executable) \(args.joined(separator: " "))...\n"

        Task.detached {
            let task = Process()
            let pipe = Pipe()

            task.executableURL = URL(fileURLWithPath: executable)
            task.arguments = args
            task.standardOutput = pipe
            task.standardError = pipe

            // Inherit system PATH so tools can be found
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:" + (env["PATH"] ?? "")
            task.environment = env

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let result = String(data: data, encoding: .utf8) ?? "No output"

                await MainActor.run {
                    if task.terminationStatus == 0 {
                        output = result.isEmpty ? "(Command ran with no output)" : result
                    } else {
                        output = "Error (exit code \(task.terminationStatus)):\n\(result)"
                    }
                    isRunning = false
                }
            } catch {
                await MainActor.run {
                    output = "Failed to run: \(error.localizedDescription)\n"
                    output += "Does the executable exist at \(executable)?"
                    isRunning = false
                }
            }
        }
    }
}
```

Improvements over the original guide:

- **Async execution** with `Task.detached` — doesn't freeze the UI
- **PATH inheritance** — finds tools in `/opt/homebrew/bin` (Apple Silicon)
- **Error handling** — shows exit codes and useful messages
- **Loading state** — visual indicator while running
- **Disabled buttons** during execution

---

## 8. Automation (Makefile)

```makefile
APP_NAME = MyLocalTool
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
```

Improvements over the original guide:

- `--no-open` prevents Tuist from opening Xcode when generating
- `-derivedDataPath` uses a local directory instead of the global `~/Library/Developer/Xcode/DerivedData`
- No dependency on `find` to locate the `.app` — uses a predictable path
- `release` target for optimized builds
- `edit` target to edit the manifest with autocomplete

---

## 9. Development Workflow

Your development loop looks like this:

```bash
# First time: generate and build
make run

# After editing Swift files:
make run

# Build only (don't open):
make build

# Clean everything and start fresh:
make clean
make run

# Edit Project.swift with Xcode autocomplete:
make edit
# (Press Ctrl+C in terminal when done editing)
```

---

## 10. .gitignore

```gitignore
# Project generated by Tuist (don't commit)
*.xcodeproj
*.xcworkspace

# Build output
.build_output/
DerivedData/
build/
Derived/

# macOS
.DS_Store

# Tuist cache
Tuist/.build/
```

---

## 11. Troubleshooting

### "No macOS SDK found"
```bash
# Make sure you have full Xcode, not just Command Line Tools
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### "Docker/Git not found"
If you're on Apple Silicon (M1/M2/M3), Homebrew tools live in `/opt/homebrew/bin`. The corrected code already includes that path in `PATH`. If you need other paths, add them to the `env["PATH"]` variable in the code.

### "App Sandbox blocks access"
Verify your `.entitlements` file does NOT contain `com.apple.security.app-sandbox` set to `true`. Check with:
```bash
# After building, verify the app's entitlements:
codesign -d --entitlements - .build_output/Build/Products/Debug/MyLocalTool.app
```

### "Tuist command not recognized"
```bash
# If installed with Mise:
mise install tuist@latest
mise use --global tuist@latest

# If installed with Homebrew:
brew upgrade tuist
```

---

## Corrections Summary vs Original Guide

| Issue in the original | Correction |
|---|---|
| `curl -Ls https://install.tuist.io \| bash` no longer works | Use `mise install tuist` or `brew install tuist` |
| `"App-Sandbox": false` in infoPlist has no effect | Use `.entitlements` file with `entitlements: .file(path:)` in Tuist |
| Synchronous `runCommand` freezes the UI | Use `Task.detached` + `MainActor.run` for async |
| `find` in DerivedData is fragile | Local `-derivedDataPath` with predictable path |
| Doesn't inherit system PATH | Configure `task.environment` with `/opt/homebrew/bin` |
| Missing `@main` App entry point | Included `MyLocalToolApp.swift` |
| Tuist API possibly outdated | Uses `.target()` and `destinations: .macOS` (current API) |
