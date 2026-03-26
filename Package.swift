// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SignalDrop",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "signaldrop",
            path: "Sources/SignalDrop",
            linkerSettings: [
                .linkedFramework("CoreWLAN"),
                .linkedFramework("SystemConfiguration"),
            ]
        )
    ]
)
