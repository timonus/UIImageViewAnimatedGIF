// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "UIImageViewAnimatedGIF",
    platforms: [.iOS(.v13), .tvOS(.v13), .macCatalyst(.v13)],
    products: [
        .library(
            name: "UIImageViewAnimatedGIF",
            targets: ["UIImageViewAnimatedGIF"]
        )
    ],
    targets: [
        .target(
            name: "UIImageViewAnimatedGIF",
            path: ".",
            sources: ["UIImageView+AnimatedGIF.m"],
            publicHeadersPath: "."
        )
    ]
)
