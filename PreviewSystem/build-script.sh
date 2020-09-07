#!/bin/bash
##===----------------------------------------------------------------------===##
##
## Compiler API service requires swiftmodule files to import shared libraries.
## This script builds those swiftmodule files used by Compile API service.
## This SwiftPM package is a collection of shared libraries and PreviewStub
## target is an anchor to build whole dependencies.
##
## The output artifact structure is:
##  distribution
##  └── PreviewStub
##      ├── checkouts
##      │   ├── JavaScriptKit
##      │   ├── ...
##      │   └── Tokamak
##      └── wasm32-unknown-wasi
##          ├── JavaScriptKit.swiftmodule
##          ├── ...
##          └── TokamakCore.swiftmodule
## 
##===----------------------------------------------------------------------===##

set -eu
preview_dir="$(cd "$(dirname $0)" && pwd)"
toolchain="$preview_dir/.toolchain/$(cat $preview_dir/../.swift-version)"
build_dir="$preview_dir/distribution"
stub_package_build_dir="$build_dir/PreviewStub"
build_config=debug

echo "-------------------------------------------------------------------------"
echo "install toolchain"
echo "-------------------------------------------------------------------------"

"$preview_dir/install-toolchain.sh"

echo "-------------------------------------------------------------------------"
echo "building PreviewStub pakcage"
echo "-------------------------------------------------------------------------"

rm -rf $stub_package_build_dir

# Build stub package for WebAssembly target
SWIFTPM_CUSTOM_BINDIR=$toolchain/usr/bin \
  "$toolchain/usr/bin/swift" build \
    --package-path "$preview_dir" \
    --triple wasm32-unknown-wasi \
    -c "$build_config" \
    --sdk "$toolchain/usr/share/wasi-sysroot" \
    -Xcc -I"$toolchain/usr/lib/swift/wasi/wasm32" \
    -Xswiftc -I"$toolchain/usr/lib/swift/wasi/wasm32"


mkdir -p $stub_package_build_dir
cp -r $preview_dir/.build/wasm32-unknown-wasi/$build_config $stub_package_build_dir/wasm32-unknown-wasi
cp -r $preview_dir/.build/checkouts $stub_package_build_dir/checkouts

echo "-------------------------------------------------------------------------"
echo "strip unnecessary files"
echo "-------------------------------------------------------------------------"

rm -rf $stub_package_build_dir/wasm32-unknown-wasi/index
rm $stub_package_build_dir/wasm32-unknown-wasi/PreviewStub
rm $(find $stub_package_build_dir/wasm32-unknown-wasi -name "*.swift.o")
rm $(find $stub_package_build_dir/wasm32-unknown-wasi -name "*.swiftmodule.o")
rm $(find $stub_package_build_dir/wasm32-unknown-wasi -name "*~partial.swiftmodule")
rm $(find $stub_package_build_dir/wasm32-unknown-wasi -name "*.d")

echo "-------------------------------------------------------------------------"
echo "workaround: copy patched modulemap into PreviewStub package"
echo "-------------------------------------------------------------------------"

cat <<EOS > $stub_package_build_dir/checkouts/JavaScriptKit/Sources/_CJavaScriptKit/include/module.modulemap
module _CJavaScriptKit {
    header "_CJavaScriptKit.h"
    export *
}
EOS