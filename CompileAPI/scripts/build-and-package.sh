#!/bin/bash
set -eu

executable=$1
workspace="$(cd "$(dirname $0)/../" && pwd)"
scripts="$workspace/scripts"
preview_dir="$workspace/../PreviewSystem"
builder_dir="$scripts/builder"
SWIFT_TAG=swift-wasm-5.6-SNAPSHOT-2022-06-30-a

echo "-------------------------------------------------------------------------"
echo "building PreviewSystem"
echo "-------------------------------------------------------------------------"
"$preview_dir/build-script.sh"
echo "done"

echo "-------------------------------------------------------------------------"
echo "downloading cross compiler toolchain for amazonlinux2"
echo "-------------------------------------------------------------------------"

mkdir -p $workspace/.build/download
if [[ ! -e $workspace/.build/download/$SWIFT_TAG-amazonlinux2_x86_64.tar.gz ]]; then
  curl -L -o $workspace/.build/download/$SWIFT_TAG-amazonlinux2_x86_64.tar.gz \
    https://github.com/swiftwasm/swift/releases/download/$SWIFT_TAG/$SWIFT_TAG-amazonlinux2_x86_64.tar.gz
fi

if [[ ! -e $workspace/toolchain ]]; then
  mkdir -p $workspace/toolchain
  tar xfzv $workspace/.build/download/$SWIFT_TAG-amazonlinux2_x86_64.tar.gz -C $workspace/toolchain --strip-components 1
fi

echo "done"
