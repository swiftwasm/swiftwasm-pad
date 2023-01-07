FROM ubuntu:focal
RUN apt-get update && DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
  apt-get install wget curl unzip git -y
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get install -y nodejs

WORKDIR /workdir/Frontend

# Install toolchain
COPY .swift-version /workdir/
COPY scripts /workdir/scripts
RUN /workdir/scripts/install-toolchain.sh

# Install NPM dependencies
COPY Frontend/package-lock.json /workdir/Frontend
COPY Frontend/package.json /workdir/Frontend
RUN npm install

# Build Preview System
COPY PreviewSystem /workdir/PreviewSystem
RUN /workdir/PreviewSystem/build-script.sh

# Build main project
COPY Frontend /workdir/Frontend
RUN npm run build
EXPOSE 8080
CMD ["npm", "run", "start"]
