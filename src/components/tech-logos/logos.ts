import typescript from "@assets/logos/typescript.svg?url";
import react from "@assets/logos/react.svg?url";
import vue from "@assets/logos/vue.svg?url";
import svelte from "@assets/logos/svelte.svg?url";
import golang from "@assets/logos/golang.svg?url";
import golangShort from "@assets/logos/golangShort.svg?url";
import rust from "@assets/logos/rust.svg?url";
import expo from "@assets/logos/expo.svg?url";
import threejs from "@assets/logos/threejs.svg?url";
import webgl from "@assets/logos/webgl.svg?url";
import afterEffects from "@assets/logos/afterEffects.svg?url";
import cinema4d from "@assets/logos/cinema4d.svg?url";
import octane from "@assets/logos/octane.svg?url";
import photoshop from "@assets/logos/photoshop.svg?url";
import zero from "@assets/logos/zero.svg?url";
import powersync from "@assets/logos/powersync.svg?url";
import tauri from "@assets/logos/tauri.svg?url";
import javascript from "@assets/logos/javascript.svg?url";

import { z } from "astro:content";

export const techNames = z.enum([
  "typescript",
  "react",
  "vue",
  "svelte",
  "go",
  "go-s",
  "rust",
  "expo",
  "three.js",
  "webgl",
  "after effects",
  "cinema 4d",
  "octane",
  "photoshop",
  "tauri",
  "zero",
  "javascript",
  "powersync",
]);

export type TechName = z.infer<typeof techNames>;

export const icons: Record<
  TechName,
  { image: string; alt: string; link: string }
> = {
  typescript: {
    image: typescript,
    alt: "typescript",
    link: "https://typescriptlang.org/",
  },
  react: {
    image: react,
    alt: "react",
    link: "https://react.dev/",
  },
  vue: {
    image: vue,
    alt: "vue",
    link: "https://vuejs.org/",
  },
  svelte: {
    image: svelte,
    alt: "svelte",
    link: "https://svelte.dev/",
  },
  go: {
    image: golang,
    alt: "Golang",
    link: "https://golang.org/",
  },
  "go-s": {
    image: golangShort,
    alt: "Golang",
    link: "https://golang.org/",
  },
  rust: {
    image: rust,
    alt: "rust",
    link: "https://rust-lang.org/",
  },
  expo: {
    image: expo,
    alt: "expo",
    link: "https://expo.dev/",
  },
  "three.js": {
    image: threejs,
    alt: "three.js",
    link: "https://threejs.org/",
  },
  webgl: {
    image: webgl,
    alt: "WebGL",
    link: "https://get.webgl.org/",
  },
  photoshop: {
    image: photoshop,
    alt: "Photoshop",
    link: "https://www.adobe.com/products/photoshop.html",
  },
  "after effects": {
    image: afterEffects,
    alt: "after effects",
    link: "https://www.adobe.com/products/aftereffects.html",
  },
  "cinema 4d": {
    image: cinema4d,
    alt: "Cinema 4D",
    link: "https://www.maxon.net/en/cinema-4d",
  },
  octane: {
    image: octane,
    alt: "Octane",
    link: "https://home.otoy.com/render/octane-render/",
  },
  zero: {
    image: zero,
    alt: "Zero",
    link: "https://zero.rocicorp.dev/",
  },
  tauri: {
    image: tauri,
    alt: "Tauri",
    link: "https://tauri.app/",
  },
  javascript: {
    image: javascript,
    alt: "Javascript",
    link: "https://developer.mozilla.org/ru/docs/Web/JavaScript",
  },
  powersync: {
    image: powersync,
    alt: "Powersync",
    link: "https://www.powersync.com/",
  },
};

export const getIcon = (icon: TechName) => {
  return icons[icon];
};
