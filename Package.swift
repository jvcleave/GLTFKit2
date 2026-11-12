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
                      url: "https://github.com/jvcleave/GLTFKit2/releases/download/0.5.15-mess.1/GLTFKit2-macOS.xcframework.zip",
                      checksum: "6cb0a7527147cd0b8baafd69ed63cbc4b53c0a8d10f5baa2983ae020710469eb")
    ]
)
