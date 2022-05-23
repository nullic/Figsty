// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Figsty",
    products: [
        .executable(name: "figsty", targets: ["Figsty"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(name: "Figsty",
                dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"),]),
    ]
)
