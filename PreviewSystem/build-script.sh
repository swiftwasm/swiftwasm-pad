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
##  ├── library.so.wasm
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

source "$preview_dir/../scripts/config.sh"

tools_dir="$preview_dir/Tools"
build_dir="$preview_dir/distribution"
stub_package_build_dir="$build_dir/PreviewStub"
shared_object_library="$build_dir/library.so.wasm"
build_config=release

echo "-------------------------------------------------------------------------"
echo "install toolchain"
echo "-------------------------------------------------------------------------"

"$preview_dir/../scripts/install-toolchain.sh"

echo "-------------------------------------------------------------------------"
echo "building PreviewStub package"
echo "-------------------------------------------------------------------------"

rm -rf $stub_package_build_dir

# Build stub package for WebAssembly target
SWIFTPM_CUSTOM_BINDIR=$TOOLCHAIN/usr/bin \
  "$TOOLCHAIN/usr/bin/swift" build \
    --package-path "$preview_dir" \
    --triple wasm32-unknown-wasi \
    -c "$build_config" -Xswiftc -Osize \
    --sdk "$TOOLCHAIN/usr/share/wasi-sysroot" \
    -Xcc -I"$TOOLCHAIN/usr/lib/swift/wasi/wasm32" \
    -Xswiftc -I"$TOOLCHAIN/usr/lib/swift/wasi/wasm32"


mkdir -p $stub_package_build_dir
cp -r $preview_dir/.build/wasm32-unknown-wasi/$build_config $stub_package_build_dir/wasm32-unknown-wasi
cp -r $preview_dir/.build/checkouts $stub_package_build_dir/checkouts

echo "-------------------------------------------------------------------------"
echo "strip unnecessary files"
echo "-------------------------------------------------------------------------"

rm -rf $stub_package_build_dir/wasm32-unknown-wasi/index
rm -f $stub_package_build_dir/wasm32-unknown-wasi/PreviewStub
rm -f $(find $stub_package_build_dir/wasm32-unknown-wasi -name "*.swift.o")
rm -f $(find $stub_package_build_dir/wasm32-unknown-wasi -name "*.swiftmodule.o")
rm -f $(find $stub_package_build_dir/wasm32-unknown-wasi -name "*~partial.swiftmodule")
rm -f $(find $stub_package_build_dir/wasm32-unknown-wasi -name "*~partial.swiftsourceinfo")
rm -f $(find $stub_package_build_dir/wasm32-unknown-wasi -name "*.swiftdeps~")
rm -f $(find $stub_package_build_dir/wasm32-unknown-wasi -name "*~partial.swiftdoc")
rm -f $(find $stub_package_build_dir/wasm32-unknown-wasi -name "*.d")

echo "-------------------------------------------------------------------------"
echo "linking shared object library"
echo "-------------------------------------------------------------------------"

link-shared-object-library() {
  local link_objects=$(
    cat "$stub_package_build_dir/wasm32-unknown-wasi/PreviewStub.product/Objects.LinkFileList" \
      | grep -v "main.swift.o"
  )

  local workdir=$(mktemp -d)

  # Extract object files from libswiftSwiftOnoneSupport.a to force link
  mkdir -p $workdir/swiftSwiftOnoneSupport
  pushd $workdir/swiftSwiftOnoneSupport > /dev/null
  "$TOOLCHAIN/usr/bin/llvm-ar" x $TOOLCHAIN/usr/lib/swift_static/wasi/libswiftSwiftOnoneSupport.a
  popd > /dev/null

  "$TOOLCHAIN/usr/bin/wasm-ld" \
    $link_objects \
    $TOOLCHAIN/usr/share/wasi-sysroot/lib/wasm32-wasi/crt1.o \
    $TOOLCHAIN/usr/lib/swift_static/wasi/wasm32/swiftrt.o \
    $TOOLCHAIN/usr/lib/clang/13.0.0/lib/wasi/libclang_rt.builtins-wasm32.a \
    $workdir/swiftSwiftOnoneSupport/*.o \
    -L$TOOLCHAIN/usr/lib/swift_static/wasi \
    -L$TOOLCHAIN/usr/share/wasi-sysroot/usr/lib/swift \
    -L$TOOLCHAIN/usr/share/wasi-sysroot/lib/wasm32-wasi \
    -lswiftSwiftOnoneSupport -lswiftWasiPthread \
    -ldl -lc++ -lm \
    -lwasi-emulated-mman -lwasi-emulated-signal -lwasi-emulated-process-clocks \
    --error-limit=0 \
    --no-gc-sections \
    --threads=1 \
    --allow-undefined \
    --relocatable \
    -o "$shared_object_library"
}

link-shared-object-library

echo "-------------------------------------------------------------------------"
echo "stripping debug info from shared object library"
echo "-------------------------------------------------------------------------"

swift run --package-path $tools_dir strip-debug $shared_object_library ${shared_object_library}-tmp
mv ${shared_object_library}-tmp $shared_object_library
