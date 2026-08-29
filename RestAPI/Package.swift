// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RestAPI",
    platforms: [.iOS(.v13), .macCatalyst(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "RestAPI", targets: ["RestAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Get", from: "2.1.0"),
        .package(url: "https://github.com/CreateAPI/NaiveDate", from: "1.0.0")
    ],
    targets: [
        .target(name: "RestAPI", dependencies: [
            .product(name: "Get", package: "Get"),
            .product(name: "NaiveDate", package: "NaiveDate")
        ], path: "Sources")
    ]
)