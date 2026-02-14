import SwiftUI

@main
struct HelloFullScreenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Enter fullscreen on launch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let window = NSApplication.shared.windows.first {
                            window.toggleFullScreen(nil)
                        }
                    }
                }
        }
    }
}
