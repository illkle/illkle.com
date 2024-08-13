<template>
  <div></div>
  <Particles v-if="!isNoscriptFallback" />
</template>
<script setup lang="ts">
const { screenWidth, screenHeight } = useScreenSize();
const { scroll } = useScroll();

const props = defineProps<{
  isNoscriptFallback?: boolean;
}>();

const FST = computed(() =>
  isScriptsReady.value ? range(0, screenHeight.value, 0, 100, scroll.value) : props.isNoscriptFallback ? 100 : 0
);

const isScriptsReady = computed(() => Boolean(screenHeight.value));

const isHidden = computed(() => props.isNoscriptFallback && screenHeight.value);

// Card transform

const cardRef = ref<HTMLElement>();

const flipped = ref(false);

const { mouseX, mouseY, hasMouse } = useMousePos();

const mousePercentX = computed(() => (hasMouse.value ? range(0, screenWidth.value, 0, 100, mouseX.value) : 50));
const mousePercentY = computed(() => (hasMouse.value ? range(0, screenHeight.value, 0, 100, mouseY.value) : 50));

const mouseDistance = computed(() =>
  hasMouse.value ? Math.abs(mousePercentX.value - 50) + Math.abs(mousePercentY.value - 50) : 0
);

const rotationX = computed(() => {
  return range(0, 100, -30, 30, mousePercentX.value) * (1 - FST.value / 100);
});
const rotationY = computed(() => {
  return range(0, 100, 30, -30, mousePercentY.value) * (1 - FST.value / 100);
});

const overlay1X = computed(() => {
  return range(0, 100, -30, 30, mousePercentX.value);
});
const overlay1Y = computed(() => {
  return range(0, 100, 30, -30, mousePercentY.value);
});

const rotationStyle = computed(() => {
  return `rotateY(${rotationX.value}deg) rotateX(${rotationY.value}deg)`;
});

const cardTR = ref<HTMLElement>();
const cardTL = ref<HTMLElement>();
const cardBL = ref<HTMLElement>();
const cardBR = ref<HTMLElement>();

const width = computed(() => range(0, 100, 315, screenWidth.value, scroll.value));
</script>
