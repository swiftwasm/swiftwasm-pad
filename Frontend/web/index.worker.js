import { WASI } from "@wasmer/wasi";
import { WasmFs } from "@wasmer/wasmfs";
import * as path from "path-browserify";
import { wrapI64Polyfill } from "./i64_polyfill";
import { wrapWASI } from "./utils"

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

wasmFs.fs.mkdirSync("/tmp", 0o777);

let theModule = null;
onmessage = event => {
  const eventData = event.data
  switch (eventData.eventType) {
    case "setModule":
      theModule = eventData.value;
      break;
    case "writeInput":
      const filename = eventData.value.filename;
      const buffer = new Uint8Array(eventData.value.buffer);
      wasmFs.fs.writeFileSync(filename, buffer);
      break;
    case "link":
      const args = eventData.value
      const wasi = new WASI({
        args: args, env: {},
        preopenDirectories: {
          "/tmp": "/tmp"
        },
        bindings: {
          ...WASI.defaultBindings,
          fs: wasmFs.fs,
          path: path,
        }
      });
      const wasiImport = wrapWASI(wasi);
      const i64Polyfill = wrapI64Polyfill(wasiImport);

      let theInstance = null;
      const importStubs = {};
      for (const importEntry of WebAssembly.Module.imports(theModule)) {
        if (importEntry.kind !== "function") {
          continue;
        }
        importStubs[importEntry.module] = importStubs[importEntry.module] || {};
        importStubs[importEntry.module][importEntry.name] = function() {
          throw new Error(`Import ${importEntry.module}::${importEntry.name} not implemented`);
        };
      }
      const importObject = {
        ...importStubs,
        wasi_snapshot_preview1: wasiImport,
        i64_polyfill: i64Polyfill,
        env: {
          _provide_mode: () => { return 0 /* linker mode */; },
          writeOutput: (ptr, length) => {
            const memory = theInstance.exports.memory;
            const uint8Array = new Uint8Array(memory.buffer, ptr, length);
            // Workaround:
            // Copy the buffer because it's not allow to transfer
            // WebAssembly.Memory directly.
            const copiedArray = uint8Array.slice();
            postMessage(copiedArray, [copiedArray.buffer])
          },
        }
      };

      WebAssembly.instantiate(theModule, importObject)
        .then(instance => {
          theInstance = instance;
          wasi.setMemory(instance.exports.memory);
          instance.exports._initialize();
          instance.exports.main();
        });
      break;
  }
}
