// https://nuxt.com/docs/api/configuration/nuxt-config
import glsl from 'vite-plugin-glsl';

export default defineNuxtConfig({
  nitro: {
    preset: 'static',
  },
  compatibilityDate: '2024-04-03',
  devtools: { enabled: true },
  modules: ['@nuxtjs/tailwindcss', '@nuxt/fonts'],
  fonts: {
    defaults: {
      weights: [200, 300, 400, 500, 600, 700, 800, 900],
    },
  },
  vite: {
    plugins: [glsl()],
  },
});
