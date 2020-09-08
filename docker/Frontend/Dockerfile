FROM swift:5.2
RUN apt update && apt install nodejs npm wget curl unzip -y
WORKDIR /workdir/Frontend

# Install toolchain
COPY .swift-version /workdir/
COPY scripts /workdir/scripts
RUN /workdir/scripts/install-toolchain.sh

# Install NPM dependencies
COPY Frontend/package-lock.json /workdir/Frontend
COPY Frontend/package.json /workdir/Frontend
RUN npm install

# Install self-managed third-party dependencies
COPY Frontend/scripts /workdir/Frontend/scripts
COPY Frontend/third-party /workdir/Frontend/third-party
RUN ./scripts/install-dependency.sh

# Build Preview System
COPY PreviewSystem /workdir/PreviewSystem
RUN /workdir/PreviewSystem/build-script.sh

# Build main project
COPY Frontend /workdir/Frontend
RUN npm run build
EXPOSE 8080
CMD ["npm", "run", "start"]