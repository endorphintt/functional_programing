import fs from "fs";
import path from "path";

const rescript = JSON.parse(fs.readFileSync("./rescript.json"));
const bsDeps = Array.isArray(rescript["bs-dependencies"]) ? rescript["bs-dependencies"] : [];
const transpileModules = ["rescript", ...bsDeps];

const config = {
  pageExtensions: ["jsx", "js"],
  env: {
    ENV: process.env.NODE_ENV,
  },
  async rewrites() {
    return [
      { source: "/health", destination: "http://localhost:8080/health" },
      { source: "/auth/:path*", destination: "http://localhost:8080/auth/:path*" },
      { source: "/users/:path*", destination: "http://localhost:8080/users/:path*" },
      { source: "/topics/:path*", destination: "http://localhost:8080/topics/:path*" },
      { source: "/tasks/:path*", destination: "http://localhost:8080/tasks/:path*" },
      { source: "/submissions/:path*", destination: "http://localhost:8080/submissions/:path*" },
      { source: "/admin/:path*", destination: "http://localhost:8080/admin/:path*" },
    ];
  },
  webpack: (config, options) => {
    const { isServer } = options;

    if (!isServer) {
      config.resolve.fallback = {
        fs: false,
        path: false,
      };
      config.watchOptions = {
        ...config.watchOptions,
        ignored: ["**/lib/bs/**", "**/lib/ocaml/**", "**/lib/rescript.lock"],
      };
    }

    config.module.rules.push({
      test: /\.m?js$/,
      use: options.defaultLoaders.babel,
      exclude: /node_modules/,
      type: "javascript/auto",
      resolve: {
        fullySpecified: false,
      },
    });

    return config;
  },
};

export default {
  transpilePackages: transpileModules,
  ...config,
};
