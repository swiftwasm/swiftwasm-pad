const path = require('path');
const CopyPlugin = require("copy-webpack-plugin");
const SwiftWebpackPlugin = require('@swiftwasm/swift-webpack-plugin')
const { execSync } = require('child_process')

const outputPath = path.resolve(__dirname, 'dist');
const staticPath = path.join(__dirname, 'static');
const projectConfig = require('querystring').parse(
  execSync(path.resolve(__dirname, "../scripts/print-config.sh")).toString().trim())

module.exports = (mode) => {
  let config = {
    entry: './js/index.js',
    mode,
    output: {
      filename: 'main.js',
      path: outputPath,
    },
    devServer: {
      inline: true,
      watchContentBase: true,
      contentBase: [outputPath],
      host: mode == 'development' ? 'dev-pad.swiftwasm.org' : 'pad.swiftwasm.org',
    },
    plugins: [
      new SwiftWebpackPlugin({
        packageDirectory: __dirname,
        swift_build: path.resolve(projectConfig.TOOLCHAIN, "usr/bin/swift-build"),
        target: 'SwiftWasmPad',
        dist: outputPath,
        config: mode == 'development' ? 'debug' : 'release'
      }),
      new CopyPlugin(
        [
          { from: staticPath, to: outputPath },
          { from: path.resolve(__dirname, "../PreviewSystem/distribution/library.so.wasm"), to: outputPath },
        ],
      ),
    ],
  };
  return config;
};
