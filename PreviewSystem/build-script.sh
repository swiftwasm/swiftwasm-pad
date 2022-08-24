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
"$TOOLCHAIN/usr/bin/swift" build \
    --package-path "$preview_dir" \
    --triple wasm32-unknown-wasi \
    -c "$build_config" -Xswiftc -Osize

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

  local inputs=(
    "$TOOLCHAIN/usr/share/wasi-sysroot/lib/wasm32-wasi/crt1-reactor.o"
    "$TOOLCHAIN/usr/lib/swift_static/wasi/wasm32/swiftrt.o"
    "$TOOLCHAIN/usr/lib/clang/13.0.0/lib/wasi/libclang_rt.builtins-wasm32.a"
    "$TOOLCHAIN/usr/lib/swift_static/wasi/libswiftWasiPthread.a"
    "$TOOLCHAIN/usr/lib/swift_static/wasi/libswiftCore.a"
    "$TOOLCHAIN/usr/lib/swift_static/wasi/libswift_Concurrency.a"
    "$TOOLCHAIN/usr/lib/swift_static/wasi/libswiftSwiftOnoneSupport.a"
    "$TOOLCHAIN/usr/lib/swift_static/wasi/libswiftWASILibc.a"
    "$TOOLCHAIN/usr/lib/swift_static/wasi/libFoundation.a"
    "$TOOLCHAIN/usr/lib/swift_static/wasi/libBlocksRuntime.a"
    "$TOOLCHAIN/usr/share/wasi-sysroot/lib/wasm32-wasi/libc.a"
    "$TOOLCHAIN/usr/share/wasi-sysroot/lib/wasm32-wasi/libc++.a"
    "$TOOLCHAIN/usr/share/wasi-sysroot/lib/wasm32-wasi/libc++abi.a"
    "$TOOLCHAIN/usr/lib/swift_static/wasi/libicuuc.a"
    "$TOOLCHAIN/usr/lib/swift_static/wasi/libicudata.a"
    "$TOOLCHAIN/usr/lib/swift_static/wasi/libicui18n.a"
    "$TOOLCHAIN/usr/share/wasi-sysroot/lib/wasm32-wasi/libwasi-emulated-mman.a"
    "$TOOLCHAIN/usr/share/wasi-sysroot/lib/wasm32-wasi/libwasi-emulated-signal.a"
    "$TOOLCHAIN/usr/share/wasi-sysroot/lib/wasm32-wasi/libwasi-emulated-process-clocks.a"
  )
  local workdir=$(mktemp -d)
  local linkfile="$workdir/LinkInputs.filelist"

  # Extract object files from libswiftSwiftOnoneSupport.a to force link
  for obj in ${inputs[@]}; do
    if [[ $obj == *.o ]]; then
      echo $obj >> $linkfile
    else
      local obj_dir=$workdir/$(basename $obj)
      mkdir -p $obj_dir
      pushd $obj_dir > /dev/null
      "$TOOLCHAIN/usr/bin/llvm-ar" x $obj
      if [[ -f $obj_dir/ImageInspectionCOFF.cpp.o ]]; then
        rm $obj_dir/ImageInspectionCOFF.cpp.o
      fi
      popd > /dev/null
      echo $obj_dir/* >> $linkfile
    fi
  done
  echo $link_objects >> $linkfile

  set -ex
  "$TOOLCHAIN/usr/bin/wasm-ld" \
    @$linkfile \
    --error-limit=0 \
    --no-gc-sections \
    --threads=1 \
    --allow-undefined --whole-archive \
    --relocatable --strip-debug \
    -o "$shared_object_library"
}

link-shared-object-library

create_relative_modulemap() {
  cat <<EOS > $stub_package_build_dir/checkouts/OpenCombine/Sources/COpenCombineHelpers/include/module.modulemap
module COpenCombineHelpers {
    umbrella header "COpenCombineHelpers.h"
    export *
}
EOS
}

create_relative_modulemap
