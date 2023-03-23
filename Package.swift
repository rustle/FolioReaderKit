// swift-tools-version:5.3
import PackageDescription

let package = Package(
	name: "FolioReaderKit",
    platforms: [
        .iOS(.v12),
    ],
	products: [
		.library(
            name: "FolioReaderKit",
            targets: ["FolioReaderKit"]
        ),
        .library(
            name: "EpubCore",
            targets: ["EpubCore"]
        ),
	],
	dependencies: [
        .package(url: "https://github.com/drearycold/ZipArchive.git", from: "2.2.5"),
        .package(url: "https://github.com/cxa/MenuItemKit.git", from: "3.0.0"),
        .package(url: "https://github.com/drearycold/ZFDragableModalTransition.git", from: "0.6.5"),
        .package(url: "https://github.com/tadija/AEXML.git", from: "4.3.3"),
        .package(url: "https://github.com/ArtSabintsev/FontBlaster.git", from: "5.1.0"),
        // .Package(url: "https://github.com/fantim/JSQWebViewController.git", majorVersion: 6, minor: 1),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.5.3"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
        .package(name: "Realm", url: "https://github.com/realm/realm-cocoa.git", from: "3.17.0"),
	],
	targets: [
        .target(
            name: "FolioReaderKit",
            dependencies: [
                "EpubCore",
                "AEXML",
                "ZipArchive",
                "FontBlaster",
                "MenuItemKit",
                "ZFDragableModalTransition",
                "SwiftSoup",
                .product(name: "RealmSwift", package: "Realm")
            ],
            resources: [
                .process("Resources/Bridge.js"),
                .process("Resources/Style.css"),
                .process("Resources/Fonts")
            ]
        ),
        .target(
            name: "EpubCore",
            dependencies: [
                "AEXML",
                "ZIPFoundation",
            ]
        ),
        .testTarget(
            name: "FolioReaderKitTests",
            dependencies: ["FolioReaderKit"]
        ),
        .testTarget(
            name: "EpubCoreTests",
            dependencies: ["EpubCore"]
        ),
	]
)
	
