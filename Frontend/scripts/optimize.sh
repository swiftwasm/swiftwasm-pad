#!/bin/bash
set -eux
frontend_root="$(cd "$(dirname $0)/../" && pwd)" 
wasm_binary="$frontend_root/dist/SwiftWasmPad.wasm"

wasm-strip "$wasm_binary"
wasm-opt -Oz "$wasm_binary" -o "$wasm_binary"