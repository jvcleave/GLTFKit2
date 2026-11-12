//swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "GLTFKit2",
    platforms: [.macOS("15.6")],
    products: [
        .library(name: "GLTFKit2",
                 targets: [ "GLTFKit2" ])
    ],
    targets: [
        .binaryTarget(name: "GLTFKit2",
                      url: "https://github.com/jvcleave/GLTFKit2/releases/download/0.5.15-mess.2/GLTFKit2-macOS.xcframework.zip",
                      checksum: "7adb78cb103747153cf646ad8203aebfb05d4fe82f850dda0cf59d8d6de5a318")
    ]
)
