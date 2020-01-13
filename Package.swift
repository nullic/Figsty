// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Figsty",
    products: [
        .executable(name: "figsty", targets: ["Figsty"]),
    ],
    targets: [
        .target(name: "Figsty", path: "Figsty"),
    ]
)
