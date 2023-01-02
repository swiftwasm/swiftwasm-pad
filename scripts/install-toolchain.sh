#!/bin/bash
set -eux
scripts_dir="$(cd "$(dirname $0)" && pwd)"
source "$scripts_dir/config.sh"

if [[ -e "$PLATFORM_TOOLCHAIN_DIR/$SWIFT_TAG" ]]; then
    echo "$SWIFT_TAG is already installed"
    exit 0
fi

case $(uname -s) in
  Darwin)
    TOOLCHAIN_DOWNLOAD=$SWIFT_TAG-macos_$(uname -m).pkg
  ;;
  Linux)
    if [ -f "/etc/os-release" ]; then
      source "/etc/os-release"
      if [ "$ID" = "ubuntu" ]; then
        TOOLCHAIN_DOWNLOAD="$SWIFT_TAG-ubuntu${VERSION_ID}_$(uname -m).tar.gz"
      elif [ "$ID" = "amzn" ]; then
        TOOLCHAIN_DOWNLOAD=$SWIFT_TAG-amazonlinux2_$(uname -m).tar.gz
      else
        echo "Unsupported Linux distribution"
        exit 1
      fi
    else
      echo "No /etc/os-release in the system"
      exit 1
    fi
  ;;
  *)
    echo "Unrecognised platform $(uname -s)"
    exit 1
  ;;
esac

TOOLCHAIN_DOWNLOAD_URL="https://github.com/swiftwasm/swift/releases/download/$SWIFT_TAG/$TOOLCHAIN_DOWNLOAD"

mkdir -p "$PLATFORM_TOOLCHAIN_DIR"
cd "$PLATFORM_TOOLCHAIN_DIR"
if [[ "$TOOLCHAIN_DOWNLOAD" == *.pkg ]]; then
    if [ ! -e "$HOME/Library/Developer/Toolchains/$SWIFT_TAG.xctoolchain" ]; then
        wget "$TOOLCHAIN_DOWNLOAD_URL"
        installer -pkg "$TOOLCHAIN_DOWNLOAD" -target CurrentUserHomeDirectory
    fi
    ln -s $HOME/Library/Developer/Toolchains/$SWIFT_TAG.xctoolchain $PLATFORM_TOOLCHAIN_DIR/$SWIFT_TAG
else
    wget "$TOOLCHAIN_DOWNLOAD_URL"
    tar xzfv "$TOOLCHAIN_DOWNLOAD"
fi
