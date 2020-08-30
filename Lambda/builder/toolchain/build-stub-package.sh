#!/bin/bash
set -eu
toolchain_builder_dir="$(cd "$(dirname $0)" && pwd)"
lambda_root="$toolchain_builder_dir/../.."

echo "-------------------------------------------------------------------------"
echo "preparing docker build image"
echo "-------------------------------------------------------------------------"
docker build $toolchain_builder_dir -t tokamak-pad-toolchain-builder

echo "-------------------------------------------------------------------------"
echo "extracting PreviewStub pakcage from Docker image"
echo "-------------------------------------------------------------------------"

rm -rf $lambda_root/distribution/PreviewStub

docker run --rm -v "$lambda_root":/workspace \
  tokamak-pad-toolchain-builder \
  cp -r /home/work/PreviewStub /workspace/distribution/

echo "-------------------------------------------------------------------------"
echo "workaround: copy patched modulemap into PreviewStub package"
echo "-------------------------------------------------------------------------"
cp $toolchain_builder_dir/module.modulemap \
  $lambda_root/distribution/PreviewStub/.build/checkouts/JavaScriptKit/Sources/_CJavaScriptKit/include/module.modulemap
