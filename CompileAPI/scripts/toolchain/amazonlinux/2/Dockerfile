FROM amazonlinux:2

WORKDIR /home/ec2-user

ARG SWIFT_TAG="swift-wasm-5.3-SNAPSHOT-2020-08-28-a"

# The build needs a package from the EPEL repo so that needs to be enabled.
# https://www.tecmint.com/install-epel-repository-on-centos/
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Update and install needed build packages
RUN yum -y update
RUN yum -y group install "development tools"
RUN yum -y install \
      git cmake clang python swig uuid-devel libicu-devel libedit-devel \
      libxml2-devel sqlite-devel ncurses-devel pkgconfig python-devel \
      python-pkgconfig libbsd-devel libuuid-devel pexpect curl-devel \
      tzdata rsync wget which python-six

# Grab an updated version of cmake
RUN wget https://cmake.org/files/v3.15/cmake-3.15.5-Linux-x86_64.tar.gz \
      && tar xvzf cmake-3.15.5-Linux-x86_64.tar.gz \
      && rm cmake-3.15.5-Linux-x86_64.tar.gz

# Add updated version of cmake to path 
ENV PATH="/home/ec2-user/cmake-3.15.5-Linux-x86_64/bin/:${PATH}"

# Cloning ninja into the root build area will cause it to be built by
# the build script and used instead of having to install a binary version
RUN git clone https://github.com/ninja-build/ninja.git

# Bootstrap the swift source and do a full checkout
RUN git clone --branch ${SWIFT_TAG} https://github.com/swiftwasm/swift.git
WORKDIR /home/ec2-user/swift
RUN ./utils/update-checkout --clone --scheme wasm/5.3

# Configure all build directories 
RUN ./utils/build-script --release \
        --wasm --build-stdlib-deployment-targets=wasi-wasm32 \
        --build-swift-dynamic-sdk-overlay=false \
        --build-swift-dynamic-stdlib=false \
        --build-swift-static-sdk-overlay \
        --build-swift-static-stdlib \
        --llvm-targets-to-build="X86;WebAssembly" \
        --stdlib-deployment-targets=wasi-wasm32 \
        --wasi-sdk=/home/ec2-user/wasi-sdk \
        --extra-cmake-options=' \
        -DWASI_ICU_URL:STRING="https://github.com/swiftwasm/icu4c-wasi/releases/download/0.5.0/icu4c-wasi.tar.xz" \
        -DWASI_ICU_MD5:STRING="d41d8cd98f00b204e9800998ecf8427e" \
        -DSWIFT_PRIMARY_VARIANT_SDK:STRING=WASI \
        -DSWIFT_PRIMARY_VARIANT_ARCH:STRING=wasm32 \
        -DSWIFT_SDKS='"'"'WASI;LINUX'"'"' \
        -DSWIFT_BUILD_SOURCEKIT=FALSE \
        -DSWIFT_ENABLE_SOURCEKIT_TESTS=FALSE \
        -DSWIFT_BUILD_SYNTAXPARSERLIB=FALSE' \
        --skip-build

# Build LLVM and dependencies
RUN ./utils/build-script --release \
        --wasm --build-stdlib-deployment-targets=wasi-wasm32 \
        --build-swift-dynamic-sdk-overlay=false \
        --build-swift-dynamic-stdlib=false \
        --build-swift-static-sdk-overlay \
        --build-swift-static-stdlib \
        --llvm-targets-to-build="X86;WebAssembly" \
        --stdlib-deployment-targets=wasi-wasm32 \
        --wasi-sdk=/home/ec2-user/wasi-sdk \
        --extra-cmake-options=' \
        -DWASI_ICU_URL:STRING="https://github.com/swiftwasm/icu4c-wasi/releases/download/0.5.0/icu4c-wasi.tar.xz" \
        -DWASI_ICU_MD5:STRING="d41d8cd98f00b204e9800998ecf8427e" \
        -DSWIFT_PRIMARY_VARIANT_SDK:STRING=WASI \
        -DSWIFT_PRIMARY_VARIANT_ARCH:STRING=wasm32 \
        -DSWIFT_SDKS='"'"'WASI;LINUX'"'"' \
        -DSWIFT_BUILD_SOURCEKIT=FALSE \
        -DSWIFT_ENABLE_SOURCEKIT_TESTS=FALSE \
        -DSWIFT_BUILD_SYNTAXPARSERLIB=FALSE' \
        --skip-build-swift

# Build swiftc
RUN /home/ec2-user/build/Ninja-ReleaseAssert/ninja-build/ninja swift \
       -C /home/ec2-user/build/Ninja-ReleaseAssert/swift-linux-x86_64

WORKDIR /home/ec2-user

RUN wget https://github.com/swiftwasm/swift/releases/download/$SWIFT_TAG/$SWIFT_TAG-linux.tar.gz \
  && tar xfzv $SWIFT_TAG-linux.tar.gz

RUN cp build/Ninja-ReleaseAssert/swift-linux-x86_64/bin/swift $SWIFT_TAG/usr/bin/swift \
  && tar cfz $SWIFT_TAG-amazonlinux2.tar.gz $SWIFT_TAG
