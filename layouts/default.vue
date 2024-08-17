<template>
  <div>
    <slot />
  </div>
</template>

<script setup>
useHead({
  bodyAttrs: {
    class: 'bg-neutral-950 text-neutral-50',
  },
});
</script>
