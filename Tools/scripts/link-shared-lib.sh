#!/bin/bash

set -e

tool="$(cd "$(dirname $0)/../" && pwd)"
scripts=$tool/scripts
source $scripts/config.sh

output=$tool/.build/library.so.wasm
workdir=$(mktemp -d)
cd $workdir

# Extract object files from libswiftSwiftOnoneSupport.a to force link
mkdir -p $workdir/swiftSwiftOnoneSupport
pushd $workdir/swiftSwiftOnoneSupport > /dev/null
"$LLVM_AR" x $SWIFT_TOOLCHAIN/lib/swift_static/wasi/libswiftSwiftOnoneSupport.a

# Compute Linker inputs
env LAMBDA_PREVIEW_STUB_PACKAGE=$PREVIEW_STUB_PACKAGE \
  swift run --package-path $tool linker-args > $workdir/linker-arguments

popd > /dev/null

# Cleanup artifact

rm -f $output

# Link shared library
"$WASM_LD" \
  $(cat $workdir/linker-arguments) \
  $SWIFT_TOOLCHAIN/share/wasi-sysroot/lib/wasm32-wasi/crt1.o \
  $SWIFT_TOOLCHAIN/lib/swift_static/wasi/wasm32/swiftrt.o \
  $SWIFT_TOOLCHAIN/lib/clang/10.0.0/lib/wasi/libclang_rt.builtins-wasm32.a \
  $workdir/swiftSwiftOnoneSupport/*.o \
  -L$SWIFT_TOOLCHAIN/lib/swift_static/wasi \
  -L$SWIFT_TOOLCHAIN/share/wasi-sysroot/usr/lib/swift \
  -L$SWIFT_TOOLCHAIN/share/wasi-sysroot/lib/wasm32-wasi \
  -lswiftCore \
  -lswiftImageInspectionShared \
  -lswiftWasiPthread \
  -licuuc \
  -licudata \
  -ldl \
  -lc++ \
  -lc++abi \
  -lc \
  -lm \
  -lwasi-emulated-mman \
  --error-limit=0 \
  --no-gc-sections \
  --no-threads \
  --allow-undefined \
  --relocatable \
  -o $output

# Strip debug info

swift run --package-path $tool strip-debug $output ${output}-tmp
mv ${output}-tmp $output
