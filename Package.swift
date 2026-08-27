// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BatteryIconApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BatteryIconApp", targets: ["BatteryIconApp"])
    ],
    targets: [
        .executableTarget(
            name: "BatteryIconApp",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit")
            ]
        ),
        .testTarget(
            name: "BatteryIconAppTests",
            dependencies: ["BatteryIconApp"]
        )
    ]
)
