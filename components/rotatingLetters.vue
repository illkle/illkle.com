<script setup lang="ts">
let num = 9;

const letters = ['K', 'E', 'L'];

const getLetter = (index: number) => {
  return letters[index % 3];
};
</script>

<template>
  <div class="w-fit flex justify-center">
    <div class="endlessRotation h-16 w-16 origin-center">
      <div
        v-for="(_, i) in Array(num)"
        class="absolute h-8 text-l font-black origin-bottom-left left-[50%]"
        :style="`transform: rotateZ(${(360 / num) * i}deg)`"
      >
        {{ getLetter(i) }}
      </div>
    </div>
  </div>
</template>

<style>
.endlessRotation {
  animation: rotation 20s infinite linear;
}
@keyframes rotation {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(359deg);
  }
}
</style>
