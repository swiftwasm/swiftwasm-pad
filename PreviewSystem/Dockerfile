FROM swift:5.2.5-bionic

ARG SWIFT_TAG=swift-wasm-5.3-SNAPSHOT-2020-08-28-a
WORKDIR /home/work/toolchain
RUN apt update && apt install wget -y
RUN wget https://github.com/swiftwasm/swift/releases/download/$SWIFT_TAG/$SWIFT_TAG-linux.tar.gz \
  && tar xfzv $SWIFT_TAG-linux.tar.gz

ENV PATH="/home/work/toolchain/$SWIFT_TAG/usr/bin:$PATH"