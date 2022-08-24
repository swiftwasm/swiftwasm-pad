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

mkdir -p $workspace/toolchain
if [[ ! -e $workspace/toolchain/$SWIFT_TAG-amazonlinux2_x86_64.tar.gz ]]; then
  curl -L -o $workspace/toolchain/$SWIFT_TAG-amazonlinux2_x86_64.tar.gz \
    https://github.com/swiftwasm/swift/releases/download/$SWIFT_TAG/$SWIFT_TAG-amazonlinux2_x86_64.tar.gz
fi

if [[ ! -e $workspace/toolchain/$SWIFT_TAG ]]; then
  tar xfzv $workspace/toolchain/$SWIFT_TAG-amazonlinux2_x86_64.tar.gz -C $workspace/toolchain
fi

echo "done"

echo "-------------------------------------------------------------------------"
echo "building \"$executable\" lambda"
echo "-------------------------------------------------------------------------"
docker run --rm -v "$workspace":/workspace -w /workspace --platform linux/amd64 \
  swift:5.6-amazonlinux2 bash -cl "swift build --product $executable -c release"
echo "done"

echo "-------------------------------------------------------------------------"
echo "download upx tool for amazonlinux2"
echo "-------------------------------------------------------------------------"

if [[ ! -e $workspace/toolchain/upx-amd64_linux ]]; then
  mkdir -p $workspace/toolchain/upx-amd64_linux
  curl -L https://github.com/upx/upx/releases/download/v3.96/upx-3.96-amd64_linux.tar.xz | \
    tar xJv -C $workspace/toolchain/upx-amd64_linux --strip-components=1
fi

echo "-------------------------------------------------------------------------"
echo "packaging shared libraries"
echo "-------------------------------------------------------------------------"
set -x
docker run --rm \
  -v "$workspace":/workspace/Lambda -v "$preview_dir/":/workspace/PreviewSystem \
  -v "$workspace/toolchain/$SWIFT_TAG":/home/work/toolchain \
  -v "$workspace/toolchain/upx-amd64_linux":/home/work/upx-amd64_linux \
  -w /workspace/Lambda --platform linux/amd64 swift:5.6-amazonlinux2 \
    bash -cl "./scripts/package.sh $executable"
echo "done"

echo "-------------------------------------------------------------------------"
echo "packaging lambda zip"
echo "-------------------------------------------------------------------------"
cd $workspace/.build/lambda/$executable
zip -q -r --symlinks $workspace/.build/lambda.zip .
