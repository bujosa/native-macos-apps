import ProjectDescription

let project = Project(
    name: "HelloWorldCool",
    targets: [
        .target(
            name: "HelloWorldCool",
            destinations: .macOS,
            product: .app,
            bundleId: "com.local.helloworldcool",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "HelloWorldCool",
            ]),
            sources: ["HelloWorldCool/Sources/**"],
            resources: ["HelloWorldCool/Resources/**"],
            entitlements: .file(path: "HelloWorldCool/HelloWorldCool.entitlements"),
            dependencies: []
        )
    ]
)
