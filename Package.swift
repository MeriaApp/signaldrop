// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Dropout",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "dropout",
            path: "Sources/Dropout",
            linkerSettings: [
                .linkedFramework("CoreWLAN"),
                .linkedFramework("SystemConfiguration"),
            ]
        )
    ]
)
