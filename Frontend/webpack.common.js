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
    entry: './web/index.js',
    mode,
    output: {
      filename: 'main.js',
      path: outputPath,
    },
    devServer: {
      inline: true,
      watchContentBase: true,
      contentBase: [outputPath],
      port: 8080,
      useLocalIp: true,
      host: "0.0.0.0",
    },
    module: {
      rules: [
        {
          test: /\.css/,
          use: [
            "style-loader",
            { loader: "css-loader", options: { url: false } },
          ]
        },
        {
          test: /\.worker\.js$/,
          use: { loader: 'worker-loader' },
        },
      ]
    },
    plugins: [
      new CopyPlugin(
        [
          { from: staticPath, to: outputPath },
          { from: path.resolve(__dirname, `.build/wasm32-unknown-wasi/${mode == 'development' ? 'debug' : 'release'}/SwiftWasmPad.wasm`), to: outputPath },
          { from: path.resolve(__dirname, "../PreviewSystem/distribution/library.so.wasm"), to: outputPath },
        ],
      ),
    ],
  };
  return config;
};
