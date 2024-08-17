<template>
  <div class="p-4 sm:p-8">
    <div class="flex flex-col justify-center">
      <div class="flex flex-col gap-2 sm:gap-8 md:flex-row justify-between">
        <h1 class="font-black flex flex-col line leading-none tracking-wider w-fit text-3xl md:text-4xl">
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

      <div class="mt-7 md:mt-24 flex flex-col gap-6 font-light text-6xl">
        <a href="https://github.com/ze-kel" class="hover:underline underline-offset-8"> GitHub </a>
        <a href="https://behance.net/ze_kel" class="hover:underline underline-offset-8 text-right md:text-left">
          Behance
        </a>
        <a href="mailto:k.kelolov@gmail.com" class="hover:underline underline-offset-8"> Email </a>
        <a href="https://t.me/ze_kel" class="hover:underline underline-offset-8 text-right md:text-left"> Telegram </a>
      </div>

      <div class="text-right text-sm font-light mt-20 group">
        <span class="opacity-0 transition-opacity group-hover:opacity-100">more stuff soon</span> +++
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
useHead({ title: 'Kirill Kleimenov | Home' });
</script>
