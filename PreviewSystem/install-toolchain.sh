#!/bin/bash
set -eu
preview_dir="$(cd "$(dirname $0)" && pwd)"
toolchain_dir="$preview_dir/.toolchain"

SWIFT_TAG=$(cat $preview_dir/../.swift-version)

if [[ -e "$toolchain_dir/$SWIFT_TAG" ]]; then
    echo "$SWIFT_TAG is already installed"
    exit 0
fi

case $(uname -s) in
  Darwin)
    TOOLCHAIN_DOWNLOAD=$SWIFT_TAG-osx.tar.gz
  ;;
  Linux)
    TOOLCHAIN_DOWNLOAD=$SWIFT_TAG-linux.tar.gz
  ;;
  *)
    echo "Unrecognised platform $(uname -s)"
    exit 1
  ;;
esac

TOOLCHAIN_DOWNLOAD_URL="https://github.com/swiftwasm/swift/releases/download/$SWIFT_TAG/$TOOLCHAIN_DOWNLOAD"

mkdir -p "$toolchain_dir"
cd "$toolchain_dir"
wget "$TOOLCHAIN_DOWNLOAD_URL" && tar xfzv "$TOOLCHAIN_DOWNLOAD"