// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "finovera",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "finovera",
            targets: ["finovera"]),
    ],
    dependencies: [
        // Dependencies will be added here as needed
    ],
    targets: [
        .target(
            name: "finovera",
            path: "app/finovera",
            exclude: ["Info.plist", "Assets.xcassets", "Preview Content"]),
        .testTarget(
            name: "finoveraTests",
            path: "app/finoveraTests",
            dependencies: ["finovera"]),
    ]
) 