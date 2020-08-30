FROM swift:5.2.5-bionic

ARG SWIFT_TAG=swift-wasm-5.3-SNAPSHOT-2020-08-28-a
WORKDIR /home/work/toolchain
RUN apt update && apt install wget -y
RUN wget https://github.com/swiftwasm/swift/releases/download/$SWIFT_TAG/$SWIFT_TAG-linux.tar.gz \
  && tar xfzv $SWIFT_TAG-linux.tar.gz

ENV CROSS_SWIFT="/home/work/toolchain/$SWIFT_TAG/usr/bin/swift"

COPY PreviewStub /home/work/PreviewStub
WORKDIR /home/work/PreviewStub
RUN $CROSS_SWIFT build --destination destination.json
RUN rm -rf .build/wasm32-unknown-wasi/debug/index
