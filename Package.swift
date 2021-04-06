// swift-tools-version:5.0
import PackageDescription

let package = Package(
	name: "FolioReaderKit",
    platforms: [
            .iOS(.v11),
    ],
	products: [
		.library(name: "FolioReaderKit", targets: ["FolioReaderKit"])
	],
	dependencies: [
        .package(url: "https://github.com/drearycold/ZipArchive.git", from: "2.2.4"),
        .package(url: "https://github.com/cxa/MenuItemKit.git", from: "3.0.0"),
        // .package(url: "https://github.com/drearycold/ZFDragableModalTransition.git", from: "0.6.3"),
        .package(url: "https://github.com/tadija/AEXML.git", from: "4.3.3"),
        .package(url: "https://github.com/ArtSabintsev/FontBlaster.git", from: "5.1.0"),
		// .Package(url: "https://github.com/fantim/JSQWebViewController.git", majorVersion: 6, minor: 1),
        .package(url: "https://github.com/realm/realm-cocoa.git", from: "3.17.0"),
	],
	targets: [
        .target(
            name: "FolioReaderKit",
            dependencies: ["AEXML", "ZipArchive", "RealmSwift", "FontBlaster", "MenuItemKit"]
        ),
		.testTarget(name: "FolioReaderKitTests", dependencies: ["FolioReaderKit"])
	]
)
	
