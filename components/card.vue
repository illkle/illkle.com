<template>
  <div class="flex h-screen w-full items-center justify-center" :style="{}">
    <div
      ref="cardRef"
      class="flex z-10"
      :style="{
        perspective: '300px',
      }"
    >
      <div
        :style="{
          transform: rotationStyle,
        }"
        class="bg-gradient-to-br from-neutral-50 to-neutral-500 w-64 h-[400px] rounded-[16px] z-10 p-0.5"
      >
        <div
          class="w-full h-full rounded-[14px] flex flex-col bg-neutral-950 p-4"
        >
          <h2 class="text-4xl font-bold">SOME THING</h2>
        </div>
      </div>
    </div>
    <canvas
      ref="canvas"
      class="absolute top-0 left-0 pointer-events-none"
    ></canvas>
  </div>
</template>
<script setup lang="ts">
const canvas = ref<HTMLCanvasElement | null>(null);
const context = ref<CanvasRenderingContext2D>();

const cardRef = ref<HTMLElement>();

const cardDimensions = ref({
  width: 0,
  height: 0,
  real: false,
});

const updateCardDimensions = () => {
  if (!cardRef.value) return;

  const bcr = cardRef.value.getBoundingClientRect();

  cardDimensions.value = { width: bcr.width, height: bcr.height, real: true };
};

onMounted(() => {
  addEventListener('resize', updateCardDimensions);
  addEventListener('scroll', updateCardDimensions);
  updateCardDimensions();
});

onUnmounted(() => {
  removeEventListener('resize', updateCardDimensions);
  removeEventListener('scroll', updateCardDimensions);
});

const { screenWidth, screenHeight } = useScreenSize();

watch([screenWidth, screenHeight], () => {
  if (!canvas.value || !context.value) return;
});

watchEffect(() => {
  if (!canvas.value) return;

  context.value = canvas.value?.getContext('2d') as CanvasRenderingContext2D;
});

const drawRect = (
  ctx: CanvasRenderingContext2D,
  w: number,
  h: number,
  x: number,
  y: number
) => {
  ctx.beginPath();
  ctx.strokeStyle = 'red';
  ctx.strokeRect(x + w / 2, y + h / 2, w, h);
  ctx.restore();
};

watch(context, (ctx) => {
  if (!ctx || !canvas.value) return;

  canvas.value.width = screenWidth.value * devicePixelRatio;
  canvas.value.height = screenHeight.value * devicePixelRatio;
  canvas.value.style.transform = `scale(${1 / devicePixelRatio})`;
  canvas.value.style.transformOrigin = 'top left';
  ctx.scale(devicePixelRatio, devicePixelRatio);
});

// Card transform
const { mouseX, mouseY } = useMousePos();

const rotationX = computed(() => {
  return range(0, screenWidth.value, -30, 30, mouseX.value);
});

const rotationY = computed(() => {
  return range(0, screenHeight.value, 30, -30, mouseY.value);
});

const rotationStyle = computed(() => {
  return `rotateY(${rotationX.value}deg) rotateX(${rotationY.value}deg  )`;
});

// Main loop
const isGeneratingParticles = ref(true);

const playing = ref(false);

let lastFrameAt: number | null = null;

const renderLoop: FrameRequestCallback = (timestamp) => {
  if (!playing.value) return;
  const secFromLast =
    timestamp && lastFrameAt ? (timestamp - lastFrameAt) / 1000 : 0;
  lastFrameAt = timestamp;
  frameUpdate(secFromLast);
  requestAnimationFrame(renderLoop);
};

const playOnVisible = () => {
  if (document.hidden) {
    playing.value = false;
  } else if (!playing.value) {
    playing.value = true;
    requestAnimationFrame(renderLoop);
  }
};

onMounted(() => {
  playing.value = true;
  requestAnimationFrame(renderLoop);
  document.addEventListener('visibilitychange', playOnVisible);
});

onUnmounted(() => {
  document.removeEventListener('visibilitychange', playOnVisible);
});

let particles: Particle[] = [];

type Particle = {
  x: number;
  y: number;
  velX: number;
  velY: number;
  ttl: number;
  size: number;
};

const drawParticle = (ctx: CanvasRenderingContext2D, p: Particle) => {
  ctx.beginPath();
  ctx.arc(p.x, p.y, p.size, 0, 2 * Math.PI);
  ctx.globalAlpha = p.ttl < 5 ? p.ttl / 5 : 1;
  ctx.fillStyle = 'rgb(255, 255, 255)';
  ctx.fill();
  ctx.restore();
};

const drawParticles = (ctx: CanvasRenderingContext2D) => {
  particles.forEach((p) => drawParticle(ctx, p));
};

const drawInfo = (ctx: CanvasRenderingContext2D) => {
  ctx.fillStyle = '#FFF';
  ctx.font = '12px';
  ctx.fillText(`Particles: ${particles.length}`, 10, 10);
};

const frameUpdate = (secFromLast: number) => {
  if (!context.value) return;
  if (isGeneratingParticles.value) {
    generateParticles(secFromLast);
  }
  simulateParticles(secFromLast);
  clearScreen(context.value);
  drawParticles(context.value);
  drawInfo(context.value);
};

const clearScreen = (ctx: CanvasRenderingContext2D) => {
  ctx.clearRect(0, 0, screenWidth.value, screenHeight.value);
};

const PPS = ref(30);

const P_SPREAD = 20;
const P_MULT = 15;

const generateParticles = (secFromLast: number) => {
  const rawCount = secFromLast * PPS.value;

  const count =
    rawCount > 1 ? Math.ceil(rawCount) : Math.random() < rawCount ? 1 : 0;

  const bXv = -rotationX.value;
  const bYv = rotationY.value;

  const bX = screenWidth.value / 2;
  const bY = screenHeight.value / 2;

  for (let i = 0; i < count; i++) {
    particles.push({
      x: getRandomNumber(
        bX - cardDimensions.value.width / 3,
        bX + cardDimensions.value.width / 3
      ),
      y: getRandomNumber(
        bY - cardDimensions.value.height / 3,
        bY + cardDimensions.value.height / 3
      ),
      velX: getRandomNumber(bXv - P_SPREAD, bXv + P_SPREAD) * P_MULT,
      velY: getRandomNumber(bYv - P_SPREAD, bYv + P_SPREAD) * P_MULT,
      ttl: getRandomNumber(3, 14),
      size: getRandomNumber(1, 7),
    });
  }
};

const SAFE_ZONE_SIZE = 30;

const simulateParticles = (secFromLast: number) => {
  particles = particles.reduce((arr, el) => {
    el.ttl = el.ttl - secFromLast;
    if (el.ttl < 0) return arr;

    el.x = el.x + el.velX * secFromLast;
    el.y = el.y + el.velY * secFromLast;

    if (
      el.x < -SAFE_ZONE_SIZE ||
      el.x > screenWidth.value + SAFE_ZONE_SIZE ||
      el.y < -SAFE_ZONE_SIZE ||
      el.y > screenHeight.value + SAFE_ZONE_SIZE
    ) {
      return arr;
    }
    arr.push(el);
    return arr;
  }, [] as Particle[]);
};
</script>
