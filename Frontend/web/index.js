import "codemirror/theme/lucario.css"
import "codemirror/lib/codemirror.css"
import "./style.css"

import { SwiftRuntime } from "javascript-kit-swift";
import { WASI } from "@wasmer/wasi";
import { WasmFs } from "@wasmer/wasmfs";
import * as path from "path-browserify"
import * as CodeMirror from "codemirror/lib/codemirror"
import "codemirror/mode/swift/swift"

global._triggerDebugger = () => {
    debugger
};

// outputHook(descriptor: number, buffer: string): void
let outputHook = null

window.swiftExports = {
  CodeMirror: CodeMirror,
  installHook: (hookFn) => {
    outputHook = hookFn
  },
  execWasm: async (arrayBuffer) => {
    const swift = new SwiftRuntime();
    const wasmFs = new WasmFs();

    const originalWriteSync = wasmFs.fs.writeSync;
    wasmFs.fs.writeSync = (fd, buffer, offset, length, position) => {
      const text = new TextDecoder("utf-8").decode(buffer);
      outputHook(fd, text)
      return originalWriteSync(fd, buffer, offset, length, position);
    };

    const wasi = new WASI({
      bindings: {
        ...WASI.defaultBindings,
        fs: wasmFs.fs
      }
    });

    const importObject = {
      executeScript: (script, length) => {
        console.log(this)
      }
    }

    const wasmBytes = new Uint8Array(arrayBuffer).buffer;
    const { instance } = await WebAssembly.instantiate(wasmBytes, {
      wasi_snapshot_preview1: wasi.wasiImport,
      wasi_unstable: wasi.wasiImport,
      javascript_kit: swift.importObjects(),
      ...importObject,
    });

    importObject.instance = instance
    swift.setInstance(instance);
    wasi.start(instance);
  }
}

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
  window.sharedFs = wasmFs.fs

  let theInstance = null;
  window.createArrayBufferFromSwiftArray = (ptr, length) => {
    const memory = theInstance.exports.memory;
    const memBuffer = new Uint8Array(memory.buffer);
    return memBuffer.slice(ptr, ptr + length);
  }

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

  window.debugWasi = wasi

  const response = await fetch("SwiftWasmPad.wasm");
  const importObject = {
    wasi_snapshot_preview1: wasi.wasiImport,
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

  theInstance = instance;
  swift.setInstance(instance);
  wasi.start(instance);
};

startWasiTask().catch(console.error);
