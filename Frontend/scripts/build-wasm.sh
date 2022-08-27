#!/bin/bash

set -eux

frontend_dir="$(cd "$(dirname $0)/.." && pwd)"

source "$frontend_dir/../scripts/config.sh"

echo PLATFORM_TOOLCHAIN_DIR=$PLATFORM_TOOLCHAIN_DIR

echo "-------------------------------------------------------------------------"
echo "install toolchain"
echo "-------------------------------------------------------------------------"

"$frontend_dir/../scripts/install-toolchain.sh"

"$TOOLCHAIN/usr/bin/swift" build --triple wasm32-unknown-wasi -Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor -Xlinker --export=main $@
