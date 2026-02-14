# Building Native macOS Apps "Headless" (No Xcode GUI)

This guide documents how to build high-performance native macOS applications using Swift and SwiftUI, while maintaining a modern workflow centered on **Cursor/VS Code** and the **Terminal**.

We treat the Xcode project infrastructure as code, avoiding the heavy `.xcodeproj` GUI entirely.

## 1. Philosophy
* **Editor:** Cursor (or VS Code).
* **Project Manager:** [Tuist](https://tuist.io/) (Generates Xcode projects from Swift code).
* **Build System:** `xcodebuild` (via Terminal/Makefile).
* **UI Framework:** SwiftUI.

## 2. Prerequisites

Ensure you have the Xcode Command Line Tools installed (included with Git/Homebrew).

```bash
# Check installation
xcode-select -p

# If missing, install via:
xcode-select --install
```

## 3. Install Tuist

Tuist is the tool that generates the Xcode project on the fly based on your configuration.

```bash
# Install Tuist
curl -Ls https://install.tuist.io | bash
```

## 4. Initialize Project

Create your directory and generate the basic template.

```bash
mkdir MyLocalTool
cd MyLocalTool

# Initialize a macOS application template with SwiftUI
tuist init --platform macos --name MyLocalTool
```

## 5. Configuration (Breaking the Sandbox)

By default, macOS apps are "Sandboxed" and cannot access system tools like `docker`, `git`, or local files. To build a DevTool, we must disable this in the project definition.

Edit `Project.swift` in Cursor:

```swift
import ProjectDescription

let project = Project(
    name: "MyLocalTool",
    targets: [
        .target(
            name: "MyLocalTool",
            destinations: .macOS,
            product: .app,
            bundleId: "com.local.tool",
            deploymentTargets: .macOS("14.0"), // Adjust to your OS version
            infoPlist: .extendingDefault(with: [
                "App-Sandbox": false, // CRITICAL: Allows access to system commands
                "com.apple.security.files.user-selected.read-write": true
            ]),
            sources: ["MyLocalTool/Sources/**"],
            resources: ["MyLocalTool/Resources/**"],
            dependencies: []
        )
    ]
)
```

## 6. The Code (SwiftUI + Shell Access)

You can edit your UI in `MyLocalTool/Sources/ContentView.swift`.

Here is a template to run local shell commands (like CLI tools) safely:

```swift
import SwiftUI
import Foundation

struct ContentView: View {
    @State private var output: String = "Ready..."

    var body: some View {
        VStack(spacing: 20) {
            Text("Local Ops Center")
                .font(.headline)

            Button("Run Docker PS") {
                // Note: You must use absolute paths or set the environment
                runCommand(executable: "/usr/local/bin/docker", args: ["ps"])
            }

            ScrollView {
                Text(output)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }

    func runCommand(executable: String, args: [String]) {
        let task = Process()
        let pipe = Pipe()
        
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = args
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let result = String(data: data, encoding: .utf8) {
                self.output = result
            }
        } catch {
            self.output = "Error: \(error.localizedDescription)"
        }
    }
}
```

## 7. Automation (Makefile)

To avoid typing long `tuist` or `xcodebuild` commands, create a `Makefile` in the root directory:

```makefile
APP_NAME = MyLocalTool

# 1. Generate the Xcode project structure from Project.swift
generate:
	tuist generate

# 2. Build and Run the app (Debug mode)
run: generate
	xcodebuild -scheme $(APP_NAME) -destination 'platform=macOS' build
	# Finds the built app in DerivedData and opens it
	open $$(find ~/Library/Developer/Xcode/DerivedData -name "$(APP_NAME).app" | head -n 1)

# 3. Clean generated files
clean:
	rm -rf *.xcodeproj *.xcworkspace DerivedData
```

## 8. Workflow

Now, your development loop is strictly inside Cursor:

1. Edit Swift files.
2. Open Terminal in Cursor.
3. Run:

```bash
make run
```

## 9. .gitignore

Since Tuist generates the project file, you should not commit it.

```gitignore
*.xcodeproj
*.xcworkspace
DerivedData/
build/
.DS_Store
```
