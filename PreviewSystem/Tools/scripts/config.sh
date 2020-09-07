if [[ -z "${SWIFT_TOOLCHAIN}" ]]; then
  echo "ERROR: Please set SWIFT_TOOLCHAIN env variable"
  exit 1
fi

ROOT="$(cd "$(dirname $0)/../../" && pwd)"
export WASM_LD=$SWIFT_TOOLCHAIN/bin/wasm-ld
export LLVM_AR=$SWIFT_TOOLCHAIN/bin/llvm-ar
export SWIFTC=$SWIFT_TOOLCHAIN/bin/swiftc
export PREVIEW_STUB_PACKAGE=$ROOT/Lambda/distribution/PreviewStub
