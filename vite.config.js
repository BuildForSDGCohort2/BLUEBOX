import { defineConfig } from "vite";
import { viteSingleFile } from "vite-plugin-singlefile";
import solid from "vite-plugin-solid";
import htmlMinimize from "@sergeymakinen/vite-plugin-html-minimize";
import compression from "vite-plugin-compression";
import tailwind from "tailwindcss";
import autoprefixer from "autoprefixer";

export default defineConfig({
  plugins: [
    viteSingleFile(),
    solid(),
    htmlMinimize(),
    compression({ algorithm: "gzip", ext: ".gz" }),
    compression({ algorithm: "brotliCompress", ext: ".br" }),
  ],

  root: "./site",

  build: {
    target: "esnext",
    assetsInlineLimit: 100000000,
    chunkSizeWarningLimit: 100000000,
    cssCodeSplit: false,
    polyfillDynamicImport: false,
    outDir: "../docs",
    emptyOutDir: false,
    brotliSize: false,
    rollupOptions: {
      inlineDynamicImports: true,
      output: {
        manualChunks: () => "everything.js",
      },
    },
  },

  css: {
    postcss: {
      plugins: [tailwind, autoprefixer],
    },
  },
});
