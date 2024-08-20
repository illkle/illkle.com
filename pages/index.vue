<template>
  <div class="p-4 sm:p-8 md:px-10 md:py-12 z-20 relative min-h-screen flex flex-col justify-between">
    <div class="flex flex-col justify-center">
      <div class="flex flex-col gap-2 sm:gap-8 md:flex-row justify-between">
        <h1 class="font-black flex flex-col leading-[0.85] tracking-wider w-fit text-3xl">
          <span class="text-[1.40em]">ZE</span>
          <span class="text-[1em]">KEL</span>
        </h1>

        <div class="text-right">
          <h2 class="text-2xl sm:text-4xl md:text-5xl font-bold leading-none">
            Kirill<br class="md:hidden" />
            Kleimenov
          </h2>
          <p class="text-xl leading-none mt-2 md:text-2xl">
            FE / Fullstack
            <span class="block text-xs font-light">ex motion designer</span>
          </p>
        </div>
      </div>

      <div class="mt-7 md:mt-32 flex flex-col gap-6 text-6xl md:w-fit">
        <a target="_blank" href="https://github.com/ze-kel" class="hover:underline underline-offset-8"> GitHub </a>
        <a
          target="_blank"
          href="https://behance.net/ze_kel"
          class="hover:underline underline-offset-8 text-right md:text-left"
        >
          Behance
        </a>
        <a target="_blank" href="mailto:k.kelolov@gmail.com" class="hover:underline underline-offset-8"> Email </a>
        <a
          target="_blank"
          href="https://t.me/ze_kel"
          class="hover:underline underline-offset-8 text-right md:text-left"
        >
          Telegram
        </a>
      </div>
    </div>

    <div class="text-right text-sm font-light mt-20 group">
      <span class="opacity-0 transition-opacity group-hover:opacity-100">more stuff soon</span> +++
    </div>
  </div>
  <Particles />
</template>

<script lang="ts" setup>
useHead({ title: 'Kirill Kleimenov | Home' });
</script>
