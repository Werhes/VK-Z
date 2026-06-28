// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VK-Z",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "VK-Z",
            targets: ["VK-Z"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.12.0"),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", from: "3.1.0")
    ],
    targets: [
        .target(
            name: "VK-Z",
            dependencies: [
                "Alamofire",
                "Kingfisher",
                .product(name: "JWTDecode", package: "JWTDecode.swift")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)