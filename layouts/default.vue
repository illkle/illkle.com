<template>
  <div>
    <slot />
  </div>
</template>

<script setup>
useHead({
  title: 'Kirill Kleimenov',
  meta: [{ name: 'description', content: 'Kirill Kleimenov, frontend/fullstack developer' }],
  bodyAttrs: {
    class: 'bg-neutral-950 text-neutral-50',
  },
});
</script>
