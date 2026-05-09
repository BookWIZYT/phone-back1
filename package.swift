// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "PhoneBack",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PhoneBack", targets: ["PhoneBack"])
    ],
    targets: [
        .executableTarget(
            name: "PhoneBack",
            dependencies: []
        )
    ]
)
