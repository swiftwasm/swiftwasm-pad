# swiftwasm-pad

![Build and deploy](https://github.com/kateinoigakukun/swiftwasm-pad/workflows/Build%20and%20deploy/badge.svg)

swiftwasm-pad is a online playground to help developers learn about Swift on Web.


- [`./CompileAPI`](https://github.com/kateinoigakukun/swiftwasm-pad/tree/master/CompileAPI) - A backend service which compiles `.swift` into WebAssembly object file. Implemented by [Swift AWS Lambda Runtime](https://github.com/swift-server/swift-aws-lambda-runtime).

- [`./Frontend`](https://github.com/kateinoigakukun/swiftwasm-pad/tree/master/Frontend) - A web frontend editor application. Implemented by [SwiftWasm](https://github.com/swiftwasm) and [Tokamak](https://github.com/TokamakUI/Tokamak).

- [`./PreviewSystem`](https://github.com/kateinoigakukun/swiftwasm-pad/tree/master/PreviewSystem) - A shared package to provide prebuilt `.swiftmodule` and wasm library.


## Run 

### Using docker-compose

```sh
$ docker-compose up
```

### Manual start up

```sh
# Build PreviewSystem
$ ./PreviewSystem/build-script.sh

# Start frontend
$ cd Frontend
$ npm install
$ npm run start

# Start backend
$ cd CompileAPI
$ export LOCAL_LAMBDA_SERVER_ENABLED=true
$ export LAMBDA_PREVIEW_STUB_PACKAGE=$(pwd)/../PreviewSystem/distribution/PreviewStub
$ swift run CompileSwiftWasm
```

## CompileAPI

CompileAPI is deployed with SwiftWasm toolchain built on Amazon Linux 2 and [`PreviewSystem`](https://github.com/kateinoigakukun/swiftwasm-pad/tree/master/PreviewSystem).
`.swiftmodule` files in PreviewSystem are used to compile user input code that can use `Tokamak` or `JavaScriptKit`. This API returns not an executable wasm binary but an object file.
The object file will be linked with prebuilt library on browser.

## Frontend

Frontend web application sends requests to CompilerAPI, link compiled object files and shared library and run linked executable wasm.
`library.so.wasm` is the shared library combined with Swift Standard Library, Tokamak and JavaScriptKit. The library is built by [`./PreviewSystem/build-script.sh`](https://github.com/kateinoigakukun/swiftwasm-pad/blob/master/PreviewSystem/build-script.sh)
This frontend application uses WebAssembly linker implemented by Swift named [chibi-link](https://github.com/kateinoigakukun/chibi-link/) to reduce CompileAPI's load and also reduce transfer data size.
