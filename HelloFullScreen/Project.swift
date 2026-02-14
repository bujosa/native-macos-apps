import ProjectDescription

let project = Project(
    name: "HelloFullScreen",
    targets: [
        .target(
            name: "HelloFullScreen",
            destinations: .macOS,
            product: .app,
            bundleId: "com.local.hellofullscreen",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "HelloFullScreen",
            ]),
            sources: ["HelloFullScreen/Sources/**"],
            resources: ["HelloFullScreen/Resources/**"],
            entitlements: .file(path: "HelloFullScreen/HelloFullScreen.entitlements"),
            dependencies: []
        )
    ]
)
