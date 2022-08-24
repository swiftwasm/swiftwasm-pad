FROM swift:5.6-amazonlinux2

ARG SWIFT_TAG=swift-wasm-5.6-SNAPSHOT-2022-06-30-a
RUN yum -y install zip wget

WORKDIR /home/work
RUN wget https://github.com/swiftwasm/swift/releases/download/$SWIFT_TAG/$SWIFT_TAG-amazonlinux2_x86_64.tar.gz
RUN tar xfzv $SWIFT_TAG-amazonlinux2_x86_64.tar.gz
RUN mv $SWIFT_TAG toolchain
# RUN mv toolchain/usr/bin/swift toolchain/usr/bin-swift \
#   && rm -rf toolchain/usr/bin \
#   && mkdir -p toolchain/usr/bin \
#   && mv toolchain/usr/bin-swift toolchain/usr/bin/swiftc
RUN rm -rf toolchain/usr/lib/swift_static/linux \
  && rm -rf toolchain/usr/lib/clang/13.0.0/lib/linux \
  && rm -rf toolchain/usr/lib/swift/pm \
  && rm -rf toolchain/usr/lib/swift/FrameworkABIBaseline
