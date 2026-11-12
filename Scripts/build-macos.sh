#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
    printf 'Usage: %s [build-directory]\n' "$0" >&2
    exit 2
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
build_root="${1:-${MESS_BUILD_CACHE_ROOT:-$HOME/Library/Developer/Xcode/DerivedData/MESS-LocalBuilds}/GLTFKit2-macOS}"
mkdir -p "$build_root"
build_root="$(cd "$build_root" && pwd -P)"
if [[ "$build_root/" == "$repo_root/"* ]]; then
    printf 'Choose a build directory outside the source checkout.\n' >&2
    exit 2
fi
build_dir="$(mktemp -d "$build_root/build.XXXXXX")"
printf 'Building in %s\n' "$build_dir"

ktx_archive="${GLTFKIT2_KTX_ARCHIVE:-$build_dir/KTX-Software-4.2.1.tar.gz}"
if [[ -z "${GLTFKIT2_KTX_ARCHIVE:-}" ]]; then
    curl --fail --location --silent --show-error --retry 3 \
        'https://raw.githubusercontent.com/jvcleave/MessEarthKit/e97c94c2412b7e4b9ae6f5f4c651ab657945a9e9/ThirdParty/Sources/KTX-Software-4.2.1.tar.gz' \
        --output "$ktx_archive"
fi
ktx_sha="$(shasum -a 256 "$ktx_archive" | awk '{print $1}')"
if [[ "$ktx_sha" != 0f80b4937208c8c26a2a47d7d80471cdd307e7194554ece0083b18e0e13e453f ]]; then
    printf 'Unexpected checksum for %s\n' "$ktx_archive" >&2
    exit 1
fi

mkdir -p "$build_dir/sources/GLTFKit2"
tar -xzf "$ktx_archive" -C "$build_dir/sources"
rsync -a --exclude='/deps/libktx/ktx.xcframework' \
    "$repo_root/GLTFKit2/" "$build_dir/sources/GLTFKit2/"
ktx_source="$build_dir/sources/KTX-Software-4.2.1"
gltf_source="$build_dir/sources/GLTFKit2"
macos_sdk="$(xcrun --sdk macosx --show-sdk-path)"

# KTX 4.2.1 predates these newer Clang diagnostics.
cmake -S "$ktx_source" -B "$build_dir/ktx" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_OSX_SYSROOT="$macos_sdk" \
    '-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64' \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=15.6 \
    '-DCMAKE_CXX_FLAGS=-Wno-error=overriding-option -Wno-error=nontrivial-memcall' \
    -DKTX_FEATURE_STATIC_LIBRARY=ON \
    -DKTX_FEATURE_TESTS=OFF \
    -DKTX_FEATURE_TOOLS=OFF \
    -DKTX_FEATURE_DOC=OFF \
    -DKTX_FEATURE_LOADTEST_APPS=OFF
cmake --build "$build_dir/ktx" --target ktx --parallel 4
xcodebuild -create-xcframework \
    -library "$build_dir/ktx/libktx.a" \
    -headers "$ktx_source/include" \
    -output "$gltf_source/deps/libktx/ktx.xcframework"

xcodebuild -project "$gltf_source/GLTFKit2.xcodeproj" \
    -scheme GLTFKit2 -configuration Release -destination 'generic/platform=macOS' \
    -derivedDataPath "$build_dir/Xcode" -jobs 4 \
    'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO MACOSX_DEPLOYMENT_TARGET=15.6 \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES CODE_SIGNING_ALLOWED=NO build

framework="$build_dir/Xcode/Build/Products/Release/GLTFKit2.framework"
notices="$framework/Versions/A/Resources/ThirdPartyNotices"
mkdir -p "$notices/KTX-Software"
cp "$repo_root/LICENSE" "$notices/GLTFKit2.txt"
cp "$gltf_source/deps/cgltf/LICENSE" "$notices/cgltf.txt"
cp "$ktx_source/LICENSE.md" "$notices/KTX-Software/"
cp -R "$ktx_source/LICENSES" "$notices/KTX-Software/"
architectures="$(lipo -archs "$framework/GLTFKit2")"
case "$architectures" in
    'arm64 x86_64'|'x86_64 arm64') ;;
    *)
        printf 'Expected arm64 and x86_64, found %s\n' "$architectures" >&2
        exit 1
        ;;
esac

bundle="$build_dir/GLTFKit2.xcframework"
archive="$build_dir/GLTFKit2-macOS.xcframework.zip"
xcodebuild -create-xcframework -framework "$framework" -output "$bundle"
packaged_framework="$bundle/macos-arm64_x86_64/GLTFKit2.framework"
# Xcode removes compiled Swift modules when creating a distributable XCFramework.
codesign --force --sign - --timestamp=none "$packaged_framework"
codesign --verify --strict "$packaged_framework"
ditto -c -k --keepParent "$bundle" "$archive"
printf 'SwiftPM archive: %s\n' "$archive"
swift package compute-checksum "$archive"
