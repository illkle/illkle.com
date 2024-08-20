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
    class: 'bg-2neutral-950 bg-gradient-to-br from-[#18181a] to-zinc-950 text-zinc-50',
  },
});
</script>
