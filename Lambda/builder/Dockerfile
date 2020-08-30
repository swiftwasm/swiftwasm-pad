FROM swift:5.2-amazonlinux2

ARG SWIFT_TAG=swift-wasm-5.3-SNAPSHOT-2020-08-28-a
RUN yum -y install zip wget

WORKDIR /home/work
RUN wget https://github.com/kateinoigakukun/swift/releases/download/$SWIFT_TAG/$SWIFT_TAG-amazonlinux2.tar.gz
RUN tar xfzv $SWIFT_TAG-amazonlinux2.tar.gz
RUN mv $SWIFT_TAG toolchain
RUN mv toolchain/usr/bin/swift toolchain/usr/bin-swift \
  && rm -rf toolchain/usr/bin \
  && mkdir -p toolchain/usr/bin \
  && mv toolchain/usr/bin-swift toolchain/usr/bin/
