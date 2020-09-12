import { WASI } from "@wasmer/wasi";
import { WasmFs } from "@wasmer/wasmfs";
import * as path from "path-browserify";
import { wrapI64Polyfill } from "./i64_polyfill";

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
      const i64Polyfill = wrapI64Polyfill(wasi.wasiImport);

      let theInstance = null;
      const importObject = {
        wasi_snapshot_preview1: wasi.wasiImport,
        i64_polyfill: i64Polyfill,
        javascript_kit: {
          swjs_set_prop: () => {},
          swjs_get_prop: () => {},
          swjs_set_subscript: () => {},
          swjs_get_subscript: () => {},
          swjs_load_string: () => {},
          swjs_call_function: () => {},
          swjs_call_function_with_this: () => {},
          swjs_create_function: () => {},
          swjs_call_new: () => {},
          swjs_destroy_ref: () => {},
        },
        env: {
          _provide_mode: () => { return 0 /* linker mode */; },
          writeOutput: (ptr, length) => {
            const memory = theInstance.exports.memory;
            const uint8Array = new Uint8Array(memory.buffer, ptr, length);
            try {
              postMessage(uint8Array, [uint8Array.buffer])
            } catch (error) {
              if (!(error instanceof TypeError) ||
                  !error.message.includes("Cannot transfer a WebAssembly.Memory")) {
                throw error;
              }
              // Workaround:
              // Copy the buffer because WebKit doesn't allow to transfer
              // WebAssembly.Memory directly.
              const copiedArray = uint8Array.slice();
              postMessage(copiedArray, [copiedArray.buffer])
            }
          },
        }
      };

      WebAssembly.instantiate(theModule, importObject)
        .then(instance => {
          theInstance = instance;
          wasi.start(instance);
        });
      break;
  }
}