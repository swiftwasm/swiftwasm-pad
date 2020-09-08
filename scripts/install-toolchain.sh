#!/bin/bash
set -eu
scripts_dir="$(cd "$(dirname $0)" && pwd)"
source "$scripts_dir/config.sh"

if [[ -e "$PLATFORM_TOOLCHAIN_DIR/$SWIFT_TAG" ]]; then
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

mkdir -p "$PLATFORM_TOOLCHAIN_DIR"
cd "$PLATFORM_TOOLCHAIN_DIR"
wget "$TOOLCHAIN_DOWNLOAD_URL" && tar xfzv "$TOOLCHAIN_DOWNLOAD"