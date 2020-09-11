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
        console.warn(text);
        break;
    }
    return originalWriteSync(fd, buffer, offset, length, position);
  };

  const wasi = new WASI({
    args: [], env: {},
    bindings: {
      ...WASI.defaultBindings,
      fs: wasmFs.fs,
      path: path,
    }
  });

  const i64Polyfill = wrapI64Polyfill(wasi.wasiImport);
  window.swiftExports = new SwiftWasmPadExport(wasmFs.fs);

  const response = await fetch("SwiftWasmPad.wasm");
  const importObject = {
    wasi_snapshot_preview1: wasi.wasiImport,
    i64_polyfill: i64Polyfill,
    javascript_kit: swift.importObjects(),
    env: {
      _provide_mode: () => { return 1 /* app mode */; },
      writeOutput: () => { /* stub */},
    }
  };

  const module = await (async () => {
    if (WebAssembly.compileStreaming) {
      return await WebAssembly.compileStreaming(response);
    } else {
      const responseArrayBuffer = await response.arrayBuffer();
      const wasmBytes = new Uint8Array(responseArrayBuffer).buffer;
      return await WebAssembly.compile(wasmBytes);
    }
  })();

  const instance = await WebAssembly.instantiate(module, importObject);
  window.swiftExports.setInstance(instance, module);
  swift.setInstance(instance);
  wasi.start(instance);
};

startWasiTask().catch(console.error);
