import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Hello World Cool")
                .font(.largeTitle.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Built without Xcode GUI")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
    }
}
