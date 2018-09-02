const webpack = require("webpack");
const path = require("path");

module.exports = {
  entry: "./src/elm-typescript-interop.ts",
  target: "node",
  output: {
    path: path.resolve(__dirname, "dist"),
    filename: "bundle.js",
    publicPath: "/"
  },
  module: {
    loaders: [
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          {
            loader: "elm-webpack-loader",
            options: {}
          }
        ]
      },
      { test: /\.ts$/, loader: "ts-loader" }
    ]
  }
};
