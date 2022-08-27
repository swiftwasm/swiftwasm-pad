#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the SwiftAWSLambdaRuntime open source project
##
## Copyright (c) 2020 Apple Inc. and the SwiftAWSLambdaRuntime project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of SwiftAWSLambdaRuntime project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

set -eu

executable=$1

target=".build/lambda/$executable"
rm -rf "$target"
mkdir -p "$target"
cp ".build/release/$executable" "$target/"

# add the target deps based on ldd
ldd ".build/release/$executable" | grep swift | awk '{print $3}' | xargs cp -Lv -t "$target"

# add swift compiler deps based on ldd
ldd "/home/work/toolchain/usr/bin/swift-frontend" | awk '{print $3}' | xargs cp -Lv -t "$target"
# don't copy system libraries
rm -f $target/libc.so.6 $target/libstdc++.so.6 $target/libm.so.6 \
  $target/libtinfo.so.6 $target/libpthread.so.0 $target/libgcc_s.so.1 \
  $target/libdl.so.2 $target/librt.so.1 $target/libz.so.1

# copy cross-compile toolchain
cp -r "/home/work/toolchain" "$target/"
required_tools=(swift-frontend swiftc swift-autolink-extract lld wasm-ld clang-13 clang)
mv $target/toolchain/usr/bin $target/toolchain/usr/bin.orig
mkdir -p $target/toolchain/usr/bin
for tool in ${required_tools[@]}; do
  echo "copying $tool"
  cp -P $target/toolchain/usr/bin.orig/$tool $target/toolchain/usr/bin/$tool
  if [ ! -L $target/toolchain/usr/bin/$tool ]; then
    strip $target/toolchain/usr/bin/$tool
    /home/work/upx-amd64_linux/upx $target/toolchain/usr/bin/$tool
  fi
done
rm -rf $target/toolchain/usr/bin.orig
rm -rf $target/toolchain/usr/lib/swift/linux
rm -rf $target/toolchain/usr/lib/swift_static/linux
rm -rf $target/toolchain/usr/lib/swift_static/clang/lib/linux
rm -rf $target/toolchain/usr/lib/clang/13.0.0/lib/linux
rm -rf $target/toolchain/usr/lib/swift/FrameworkABIBaseline
rm -rf $target/toolchain/usr/lib/swift/pm
rm -rf $target/toolchain/usr/lib/swift/wasi/
rm -rf $target/toolchain/usr/lib/swift_static/clang/include/sanitizer
rm -rf $target/toolchain/usr/lib/swift_static/clang/include/xray
rm -rf $target/toolchain/usr/lib/swift_static/clang/include/ppc_wrappers
rm -rf $target/toolchain/usr/lib/swift_static/clang/include/openmp_wrappers
for file in $(find $target/toolchain/usr/lib/ -name "*.swiftdoc" -or -name "*.swiftinterface"); do
  rm -f $file
done

# copy preview stub package
cp -r "../PreviewSystem/distribution/PreviewStub" "$target/"
for repo in $target/PreviewStub/checkouts/*; do
  # if the repo contains include directories, keep them
  if [ ! $(find $repo -type d -name include | wc -l) -gt 0 ]; then
    rm -rf $repo
  fi
done
for file in $(find $target/PreviewStub/wasm32-unknown-wasi -name "*.swiftdoc" -or -name "*.swiftinterface" -or -name "*.wasm"); do
  rm -f $file
done


ln -s $executable $target/bootstrap
