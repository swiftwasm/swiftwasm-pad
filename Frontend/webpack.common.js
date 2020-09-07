const path = require('path');
const Watchpack = require('watchpack');
const CopyPlugin = require("copy-webpack-plugin");
const SwiftWebpackPlugin = require('@swiftwasm/swift-webpack-plugin')

const outputPath = path.resolve(__dirname, 'dist');
const staticPath = path.join(__dirname, 'static');

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
        target: 'SwiftWasmPad',
        dist: outputPath,
        config: mode == 'development' ? 'debug' : 'release'
      }),
      new CopyPlugin(
        [
          { from: staticPath, to: outputPath },
          { from: path.join(__dirname, "../PreviewSystem/distribution/library.so.wasm"), to: outputPath },
        ],
      ),
    ],
  };
  return config;
};
