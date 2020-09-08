FROM swift:5.2 AS preview-stub-builder
RUN apt update && apt install wget -y
WORKDIR /workdir

# Build Preview System
COPY .swift-version /workdir/
COPY scripts /workdir/scripts
COPY PreviewSystem /workdir/PreviewSystem
RUN /workdir/PreviewSystem/build-script.sh

FROM swift:5.2-amazonlinux2

ARG SWIFT_TAG=swift-wasm-5.3-SNAPSHOT-2020-08-28-a
RUN yum -y install zip wget

WORKDIR /workdir
RUN wget https://github.com/kateinoigakukun/swift/releases/download/$SWIFT_TAG/$SWIFT_TAG-amazonlinux2.tar.gz
RUN tar xfzv $SWIFT_TAG-amazonlinux2.tar.gz
RUN mv $SWIFT_TAG /workdir/toolchain

# Build main project
COPY CompileAPI /workdir/CompileAPI
WORKDIR /workdir/CompileAPI

ENV LOCAL_LAMBDA_SERVER_ENABLED true
ENV LAMBDA_PREVIEW_STUB_PACKAGE /workdir/PreviewSystem/distribution/PreviewStub
ENV LAMBDA_SWIFTC /workdir/toolchain/usr/bin/swiftc

RUN swift build
COPY --from=preview-stub-builder /workdir/PreviewSystem/distribution /workdir/PreviewSystem/distribution

EXPOSE 7000
CMD ["swift", "run", "CompileSwiftWasm"]