// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Headroom",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "HeadroomCore", targets: ["HeadroomCore"]),
        .executable(name: "Headroom", targets: ["Headroom"]),
    ],
    targets: [
        .target(name: "HeadroomCore", path: "Sources/HeadroomCore"),
        .executableTarget(
            name: "Headroom",
            dependencies: ["HeadroomCore"],
            path: "Sources/Headroom"
        ),
        .testTarget(
            name: "HeadroomTests",
            dependencies: ["HeadroomCore"],
            path: "Tests/HeadroomTests",
            resources: [.copy("fixture.json")]
        ),
    ]
)
