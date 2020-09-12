import * as CodeMirror from "codemirror/lib/codemirror"
import { SwiftRuntime } from "javascript-kit-swift";
import { WASI } from "@wasmer/wasi";
import { WasmFs } from "@wasmer/wasmfs";
import Worker from "./index.worker.js"

export class SwiftWasmPadExport {

  constructor(sharedFs) {
    this.CodeMirror = CodeMirror;
    this.outputHook = null;
    this.sharedFs = sharedFs;
    this.sharedLibrary = fetch("library.so.wasm")
    this.linkerWorker = new Worker();
  }

  installHook(hookFn) {
    // outputHook(descriptor: number, buffer: string): void
    this.outputHook = hookFn;
  }

  setInstance(instance, module) {
    this.theInstance = instance; 
    this.theModule = module;
    this.linkerWorker.postMessage({ eventType: "setModule", value: module });
  }

  _triggerDebugger() {
    debugger
  }

  async execWasm(arrayBuffer) {
    const swift = new SwiftRuntime();
    const wasmFs = new WasmFs();

    const originalWriteSync = wasmFs.fs.writeSync;
    wasmFs.fs.writeSync = (fd, buffer, offset, length, position) => {
      const text = new TextDecoder("utf-8").decode(buffer);
      if (this.outputHook) {
        this.outputHook(fd, text);
      }
      return originalWriteSync(fd, buffer, offset, length, position);
    };

    const wasi = new WASI({
      bindings: {
        ...WASI.defaultBindings,
        fs: wasmFs.fs
      }
    });

    const wasmBytes = new Uint8Array(arrayBuffer).buffer;
    const { instance } = await WebAssembly.instantiate(wasmBytes, {
      wasi_snapshot_preview1: wasi.wasiImport,
      wasi_unstable: wasi.wasiImport,
      javascript_kit: swift.importObjects(),
    });

    swift.setInstance(instance);
    wasi.start(instance);
  }
}