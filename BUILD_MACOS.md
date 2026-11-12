# macOS builds

This fork packages GLTFKit2 for macOS 15.6 and later on Apple Silicon and
Intel. This build uses the GLTFKit2 0.5.15 source at
`e69e354c4f31ea07b7816b8cbe2ddb28e897d073` and KTX-Software 4.2.1 at
`170e75893e3d232a2c4f241afe199256f8abb6f9`.

## SwiftPM

Add the package at the exact release and use the `GLTFKit2` product.

```swift
.package(url: "https://github.com/jvcleave/GLTFKit2.git", exact: "0.5.15-mess.3")
```

For a command-line executable, add a runtime search path for the embedded
framework. With the framework beside the executable, use
`swift run -Xlinker -rpath -Xlinker @executable_path <executable>`.

## Rebuild

Build with Xcode and CMake 3.30 or later. The `0.5.15-mess.3` binary was
built with Xcode 26.3 and Swift 6.2.4.

```sh
Scripts/build-macos.sh
```

The script verifies the KTX source archive from the pinned
[MessEarthKit revision](https://github.com/jvcleave/MessEarthKit/blob/e97c94c2412b7e4b9ae6f5f4c651ab657945a9e9/ThirdParty/PROVENANCE.json).
For an offline build, set `GLTFKIT2_KTX_ARCHIVE` to the path of a local copy of
`KTX-Software-4.2.1.tar.gz`. The same checksum applies. The build stages the
GLTFKit2 source, compiles KTX for both architectures and embeds it statically
in the macOS framework. The framework carries the GLTFKit2, cgltf and
KTX-Software notices.

The script prints the path to `GLTFKit2-macOS.xcframework.zip` and its SwiftPM
checksum. It writes all outputs under the supplied build directory or under
`GLTFKit2-macOS` in the local build cache. Release maintainers set the URL
and checksum in `Package.swift`, tag that commit and attach the matching
archive to the GitHub release. Use an exact version when resolving the package.
