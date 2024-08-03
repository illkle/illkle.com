<template>
  <div
    class="relative z-50 p-4 cardContent border-2 border-transparent transition-colors duration-300"
    :class="[!isTransitioned && 'border-white rounded-lg']"
    :style="{ width: `${width}px` }"
  >
    <h1 class="text-2xl font-bold">KIRILL KLEYMENOV</h1>
    <div
      :class="[
        isTransitioned ? 'max-h-0 opacity-0 mt-0' : 'max-h-56 mt-10',
        'transition-all duration-300',
      ]"
    >
      <h2 class="text-xl">
        Frontend focused fullstack developer.
        <br />Ex motion designer
      </h2>
    </div>
  </div>
</template>

<script setup lang="ts">
const { screenWidth, screenHeight } = useScreenSize();
const { scroll } = useScroll();

const width = computed(() =>
  range(0, screenHeight.value, 350, screenWidth.value, scroll.value)
);

const isTransitioned = computed(() => scroll.value > screenHeight.value / 2);
</script>

<style></style>
