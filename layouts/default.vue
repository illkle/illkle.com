<template>
  <div>
    <slot />
  </div>
</template>

<script setup>
useHead({
  bodyAttrs: {
    class: 'bg-black text-neutral-50',
  },
});
</script>
