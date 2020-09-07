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
build_dir="$preview_dir/distribution"
stub_package_build_dir="$build_dir/PreviewStub"
build_config=debug

echo "-------------------------------------------------------------------------"
echo "preparing docker build image for preview stub package"
echo "-------------------------------------------------------------------------"
docker build $preview_dir -t tokamak-pad-preview-stub-builder

echo "-------------------------------------------------------------------------"
echo "building PreviewStub pakcage from Docker image"
echo "-------------------------------------------------------------------------"

rm -rf $stub_package_build_dir

# Build stub package for WebAssembly target
docker run --rm -v "$preview_dir":/workspace -w /workspace \
  tokamak-pad-preview-stub-builder \
  bash -cl "swift build --destination destination.json -c $build_config"

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