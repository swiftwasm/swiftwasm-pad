import "codemirror/theme/lucario.css"
import "codemirror/lib/codemirror.css"
import "./style.css"

import { SwiftRuntime } from "javascript-kit-swift";
import { WASI } from "@wasmer/wasi";
import { WasmFs } from "@wasmer/wasmfs";
import * as path from "path-browserify";
import "codemirror/mode/swift/swift";

import { SwiftWasmPadExport } from "./export";
import { wrapI64Polyfill } from "./i64_polyfill";

const startWasiTask = async () => {

  const swift = new SwiftRuntime();
  const wasmFs = new WasmFs();

  // Output stdout and stderr to console
  const originalWriteSync = wasmFs.fs.writeSync;
  wasmFs.fs.writeSync = (fd, buffer, offset, length, position) => {
    const text = new TextDecoder("utf-8").decode(buffer);
    switch (fd) {
      case 1:
        console.log(text);
        break;
      case 2:
        console.error(text);
        break;
    }
    return originalWriteSync(fd, buffer, offset, length, position);
  };

  wasmFs.fs.mkdirSync("/tmp", 0o777);

  let wasi = new WASI({
    args: [], env: {},
    preopenDirectories: {
      "/tmp": "/tmp"
    },
    bindings: {
      ...WASI.defaultBindings,
      fs: wasmFs.fs,
      path: path,
    }
  });

  const i64Polyfill = wrapI64Polyfill(wasi);

  window.swiftExports = new SwiftWasmPadExport(wasmFs.fs);

  const response = await fetch("SwiftWasmPad.wasm");
  const importObject = {
    wasi_snapshot_preview1: wasi.wasiImport,
    i64_polyfill: i64Polyfill,
    javascript_kit: swift.importObjects(),
  };

  const { instance } = await (async () => {
    if (WebAssembly.instantiateStreaming) {
      return await WebAssembly.instantiateStreaming(response, importObject);
    } else {
      const responseArrayBuffer = await response.arrayBuffer();
      const wasmBytes = new Uint8Array(responseArrayBuffer).buffer;
      return await WebAssembly.instantiate(wasmBytes, importObject);
    }
  })();

  window.swiftExports.setInstance(instance);
  swift.setInstance(instance);
  wasi.start(instance);
};

startWasiTask().catch(console.error);
