FROM swift:5.6-focal AS builder

# Build main project
COPY CompileAPI /workdir/CompileAPI
WORKDIR /workdir/CompileAPI
RUN --mount=type=cache,target=/workdir/CompileAPI/.build \
  swift build -c release -Xswiftc -g
RUN --mount=type=cache,target=/workdir/CompileAPI/.build \
  cp "$(swift build -c release --show-bin-path)/CompileSwiftWasm" ./

FROM swift:5.6-focal-slim

ARG SWIFT_TAG=swift-wasm-5.6-SNAPSHOT-2022-06-30-a
ARG SWIFT_PLATFORM=ubuntu20.04
ARG OS_ARCH_SUFFIX=x86_64

RUN apt-get -q update && apt-get -q install -y curl && rm -rf /var/lib/apt/lists/* && \
    SWIFT_TARBALL="${SWIFT_TAG}-${SWIFT_PLATFORM}_${OS_ARCH_SUFFIX}.tar.gz" && \
    curl -L -o $SWIFT_TARBALL \
    https://github.com/swiftwasm/swift/releases/download/$SWIFT_TAG/$SWIFT_TARBALL && \
    mkdir -p toolchain && \
    tar xfzv $SWIFT_TARBALL -C toolchain --strip-components 1 && \
    apt-get purge --auto-remove -y curl && \
    rm $SWIFT_TARBALL && \
    mv toolchain/usr/bin toolchain/usr/bin.orig && \
    mkdir -p toolchain/usr/bin && \
    for tool in swift-frontend swiftc swift-autolink-extract lld wasm-ld clang-13 clang; do \
      cp -P toolchain/usr/bin.orig/$tool $target/toolchain/usr/bin/$tool; \
    done && \
    rm -rf toolchain/usr/bin.orig && \
    rm -rf toolchain/usr/lib/swift_static/linux && \
    rm -rf toolchain/usr/lib/swift_static/clang/lib/linux && \
    rm -rf toolchain/usr/lib/clang/13.0.0/lib/linux && \
    rm -rf toolchain/usr/lib/swift/FrameworkABIBaseline && \
    rm -rf toolchain/usr/lib/swift/pm && \
    rm -rf toolchain/usr/lib/swift/wasi/ && \
    rm -rf toolchain/usr/lib/swift_static/clang/include/sanitizer && \
    rm -rf toolchain/usr/lib/swift_static/clang/include/xray && \
    rm -rf toolchain/usr/lib/swift_static/clang/include/ppc_wrappers && \
    rm -rf toolchain/usr/lib/swift_static/clang/include/openmp_wrappers && \
    for file in $(find toolchain/usr/lib/ -name "*.swiftdoc" -or -name "*.swiftinterface"); do \
      rm -f $file; \
    done

COPY PreviewSystem/distribution/PreviewStub /workdir/PreviewSystem/distribution/PreviewStub
ENV LAMBDA_PREVIEW_STUB_PACKAGE /workdir/PreviewSystem/distribution/PreviewStub

COPY --from=builder /workdir/CompileAPI/CompileSwiftWasm .

EXPOSE 8080
CMD ["./CompileSwiftWasm", "serve", "--hostname", "0.0.0.0"]
