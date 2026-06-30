// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VKZ",
    platforms: [
        .iOS(.v17),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "VKZ",
            targets: ["VKZ"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.12.0"),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", from: "3.1.0")
    ],
    targets: [
        .target(
            name: "VKZ",
            dependencies: [
                "Alamofire",
                "Kingfisher",
                .product(name: "JWTDecode", package: "JWTDecode.swift")
            ],
            path: ".",
            exclude: [
                "Package.swift",
                "README.md",
                "Resources/Info.plist",
                "Resources/Assets.xcassets"
            ],
            sources: [
                "VKZApp.swift",
                "Models/VKMusicModels.swift",
                "Services/AudioPlayerManager.swift",
                "Services/VKApiService.swift",
                "Views/MainTabView.swift",
                "Views/Auth/VKAuthView.swift",
                "Views/Mix/MixView.swift",
                "Views/Player/PlayerView.swift",
                "Views/Playlists/PlaylistsView.swift",
                "Views/Search/SearchView.swift"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)