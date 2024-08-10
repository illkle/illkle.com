<template>
  <div
    v-if="!isHidden"
    ref="cardRef"
    class="flex z-10"
    :class="isScriptsReady ? 'fixed' : isNoscriptFallback ? 'sticky' : 'absolute'"
    :style="{
      perspective: '900px',
      left: '50%',
      top: `${range(0, 100, 50, 0, FST)}%`,
      transform: !isScriptsReady && isNoscriptFallback ? 'none' : `translate(-50%,  ${range(0, 100, -50, 0, FST)}%)`,
    }"
  >
    <div
      :style="{
        transform: rotationStyle,
      }"
      class="relative overflow-hidden rounded-lg bg-neutral-950"
    >
      <div
        class="w-full flex flex-col relative box-border border-2 border-transparent overflow-hidden"
        :style="{
          width: isScriptsReady ? `${range(0, 100, 315, screenWidth, FST)}px` : isNoscriptFallback ? '100vw' : '315px',
          borderRadius: `${range(0, 100, 16, 0, FST)}px`,
          borderColor: `rgba(255, 255,255, ${range(0, 100, 1, 0, FST)})`,
        }"
      >
        <!--Card position points to grab it's coordinates relative to screen-->
        <div ref="cardTL" class="absolute top-1 left-1"></div>
        <div ref="cardTR" class="absolute top-1 right-1"></div>
        <div ref="cardBR" class="absolute bottom-1 right-1"></div>
        <div ref="cardBL" class="absolute bottom-1 left-1"></div>

        <!--Card overlays-->
        <img
          src="/public/over1.jpg"
          class="absolute left-1/2 top-1/2 w-[1500px] h-[1500px] z-20 max-w-[unset] pointer-events-none"
          :style="{
            opacity: range(0, 100, 0.05, 0, FST),
            transform: `translateX(calc(-50% + ${overlay1X}%)) translateY(calc(-50% + ${overlay1Y}%))`,
          }"
        />
        <img
          v-for="o in [
            { h: 0, x: 0, y: 0 },
            { h: 120, x: -100, y: -50 },
            { h: 240, x: -50, y: -100 },
          ]"
          src="/public/text.jpg"
          class="mix-blend-plus-lighter absolute w-[550px] h-[550px] z-20 max-w-[unset] pointer-events-none"
          style="mask: url(_nuxt/public/over3.2.jpg) luminance"
          :style="{
            maskRepeat: 'no-repeat',
            maskPosition: `${range(0, 100, 0, 100, mousePercentX)}% ${range(0, 100, 0, 100, mousePercentY)}%`,
            maskSize: '1200px 1000px',
            opacity: range(0, 100, 0.7, 0, FST),
            filter: `hue-rotate(${o.h}deg)`,
            transform: `translate(${o.x}px, ${o.y}px)`,
          }"
        />

        <!--Card Inner content-->
        <div class="relative text-neutral-200">
          <h1 class="text-2xl font-bold p-6">KIRILL KLEYMENOV</h1>
          <div
            class="h-36"
            :style="{
              maxHeight: range(0, 100, 224, 0, FST) + 'px',
            }"
          ></div>
        </div>
        <div
          class="box-border"
          :style="{
            opacity: range(0, 100, 1, 0, FST),
            marginTop: range(0, 100, 40, 0, FST) + 'px',
            maxHeight: range(0, 100, 224, 0, FST) + 'px',
          }"
        >
          <h2 class="text-xl pt-10 p-6 py-10">
            Frontend focused fullstack developer.
            <br />Ex motion designer
          </h2>
        </div>
      </div>
    </div>
  </div>
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

const cardPoints = ref({
  tl: { x: 0, y: 0 },
  bl: { x: 0, y: 0 },
  tr: { x: 0, y: 0 },
  br: { x: 0, y: 0 },
});

const addScrollToY = (p: Point) => {
  p.y += scroll.value;
  return p;
};
const updateCardPoint = () => {
  if (!cardTL.value || !cardBL.value || !cardTR.value || !cardBR.value) return;
  cardPoints.value.tl = addScrollToY(cardTL.value.getBoundingClientRect());
  cardPoints.value.bl = addScrollToY(cardBL.value.getBoundingClientRect());
  cardPoints.value.tr = addScrollToY(cardTR.value.getBoundingClientRect());
  cardPoints.value.br = addScrollToY(cardBR.value.getBoundingClientRect());
};

watch([FST, rotationStyle], updateCardPoint);

const width = computed(() => range(0, 100, 315, screenWidth.value, scroll.value));
</script>
