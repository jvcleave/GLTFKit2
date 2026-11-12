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
                      url: "https://github.com/jvcleave/GLTFKit2/releases/download/0.5.15-mess.3/GLTFKit2-macOS.xcframework.zip",
                      checksum: "f4d6e86044f459795cf0ba41cde2317b00194f68dfe9f9b53acf153022b0ef4c")
    ]
)
