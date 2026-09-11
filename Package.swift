// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Pildot",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Pildot", targets: ["Pildot"])
    ],
    targets: [
        .executableTarget(
            name: "Pildot",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit")
            ]
        ),
        .testTarget(
            name: "PildotTests",
            dependencies: ["Pildot"]
        )
    ]
)
