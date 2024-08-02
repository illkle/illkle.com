<template>
  <div
    class="flex h-screen w-screen overflow-hidden items-center justify-center"
    :style="{}"
  >
    <div
      ref="cardRef"
      class="flex z-10"
      :style="{
        perspective: '500px',
      }"
    >
      <div></div>
      <div
        :style="{
          transform: rotationStyle,
        }"
        class="w-[600px] h-[400px] rounded-[16px] p-0.5 relative overflow-hidden"
      >
        <div
          class="w-full h-full rounded-[14px] flex flex-col p-4 relative backdrop-blur-lg border-2 bg-neutral-950 bg-opacity-50"
        >
          <img
            src="/public/over1.jpg"
            class="absolute left-1/2 top-1/2 w-[1500px] h-[1500px] z-20 max-w-[unset] opacity-50 pointer-events-none"
            :style="{
              transform: `translateX(calc(-50% + ${overlay1X}%)) translateY(calc(-50% + ${overlay1Y}%))`,
            }"
          />
          <div ref="cardTL" class="absolute top-1 left-1"></div>
          <div ref="cardTR" class="absolute top-1 right-1"></div>
          <div ref="cardBR" class="absolute bottom-1 right-1"></div>
          <div ref="cardBL" class="absolute bottom-1 left-1"></div>

          <div class="relative z-50">
            <h2 class="text-4xl font-bold">SOME THING</h2>

            <div>Frametime: {{ frameTime.toFixed(6) }}</div>

            <div>Time budget: {{ (1000 / fps).toFixed(4) }}</div>
            <div>FPS {{ fps.toFixed(0) }} (approx)</div>

            <input v-model="PPS" class="bg-neutral-950" type="number" />

            <button
              class="bg-neutral-50"
              @click="() => (isGeneratingParticles = !isGeneratingParticles)"
            >
              PLAY PAUSE
            </button>
          </div>
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

const { screenWidth, screenHeight } = useScreenSize();

watchEffect(() => {
  if (!canvas.value) return;
  context.value = canvas.value?.getContext('2d') as CanvasRenderingContext2D;
});

watch([context, screenWidth, screenHeight], (upd) => {
  if (!upd[0] || !canvas.value) return;

  canvas.value.width = upd[1] * devicePixelRatio;
  canvas.value.height = upd[2] * devicePixelRatio;
  canvas.value.style.transform = `scale(${1 / devicePixelRatio})`;
  canvas.value.style.transformOrigin = 'top left';
  upd[0].scale(devicePixelRatio, devicePixelRatio);
});

// Card transform
const { mouseX, mouseY } = useMousePos();

const mousePercentX = computed(() =>
  range(0, screenWidth.value, 0, 100, mouseX.value)
);
const mousePercentY = computed(() =>
  range(0, screenHeight.value, 0, 100, mouseY.value)
);

const rotationX = computed(() => {
  return range(0, 100, -30, 30, mousePercentX.value);
});
const rotationY = computed(() => {
  return range(0, 100, 30, -30, mousePercentY.value);
});

const overlay1X = computed(() => {
  return range(0, 100, -30, 30, mousePercentX.value);
});
const overlay1Y = computed(() => {
  return range(0, 100, 30, -30, mousePercentY.value);
});

const rotationStyle = computed(() => {
  return `rotateY(${rotationX.value}deg) rotateX(${rotationY.value}deg  )`;
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

const updateCardPoint = () => {
  if (!cardTL.value || !cardBL.value || !cardTR.value || !cardBR.value) return;
  cardPoints.value.tl = cardTL.value.getBoundingClientRect();
  cardPoints.value.bl = cardBL.value.getBoundingClientRect();
  cardPoints.value.tr = cardTR.value.getBoundingClientRect();
  cardPoints.value.br = cardBR.value.getBoundingClientRect();
};

onMounted(() => {
  addEventListener('resize', updateCardPoint);
  addEventListener('mousemove', updateCardPoint);
  addEventListener('scroll', updateCardPoint);
});

// Main loop
const isGeneratingParticles = ref(false);

const playing = ref(true);

let lastFrameAt: number | null = null;

const frameTime = ref(0);
const fps = ref(0);
let framenum = 1;

const renderLoop: FrameRequestCallback = (timestamp) => {
  if (!playing.value) return;

  if (framenum === 60) {
    performance.mark('frameStart');
    framenum = 0;
  } else {
    framenum++;
  }

  const secFromLast =
    timestamp && lastFrameAt ? (timestamp - lastFrameAt) / 1000 : 0;
  lastFrameAt = timestamp;
  frameUpdate(secFromLast);

  if (framenum == 0) {
    performance.mark('frameEnd');
    const p = performance.measure('frame', 'frameStart', 'frameEnd');

    fps.value = 1 / secFromLast;
    frameTime.value = p.duration;
  }
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

const drawParticles = (ctx: CanvasRenderingContext2D) => {
  ctx.fillStyle = 'rgb(255, 255, 255)';
  ctx.beginPath();
  particles.forEach((p) => {
    ctx.moveTo(p.x, p.y);
    ctx.arc(p.x, p.y, p.size, 0, 2 * Math.PI);
  });
  ctx.fill();
};

const drawInfo = (ctx: CanvasRenderingContext2D) => {
  ctx.fillStyle = '#FFF';
  ctx.font = '12px';
  ctx.fillText(`Particles: ${particles.length}`, 10, 10);

  Object.values(cardPoints.value).forEach((p) => {
    ctx.fillStyle = 'red';
    ctx.beginPath();
    ctx.moveTo(p.x, p.y);
    ctx.arc(p.x, p.y, 10, 0, 2 * Math.PI);
    ctx.fill();
  });
};

const drawLines = (ctx: CanvasRenderingContext2D) => {
  const fromMouseToCard = [
    cardPoints.value.tl,
    cardPoints.value.tr,
    cardPoints.value.br,
    cardPoints.value.bl,
  ].map((v) => {
    return { from: { x: mouseX.value, y: mouseY.value }, to: v };
  });

  const lFactor = 2;
  const toDraw = fromMouseToCard.map((a) => {
    const mX = a.to.x - a.from.x;
    const mY = a.to.y - a.from.y;

    return {
      from: a.to,
      to: { x: a.to.x + mX * lFactor, y: a.to.y + mY * lFactor },
    };
  });

  for (let i = 0; i < toDraw.length; i++) {
    const a = toDraw[i === 0 ? toDraw.length - 1 : i - 1];
    const b = toDraw[i];
    ctx.beginPath();
    ctx.moveTo(a.from.x, a.from.y);

    ctx.lineTo(a.to.x, a.to.y);
    ctx.lineTo(b.to.x, b.to.y);
    ctx.lineTo(b.from.x, b.from.y);
    ctx.lineWidth = 15;

    ctx.strokeStyle = '';
    ctx.fill();
  }
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
  drawLines(context.value);
};

const clearScreen = (ctx: CanvasRenderingContext2D) => {
  ctx.clearRect(0, 0, screenWidth.value, screenHeight.value);
};

const PPS = ref(100);

const P_SPREAD = 20;
const P_MULT = 15;

const getDistanceBetweenPoints = (a: Point, b: Point) => {
  return Math.abs(Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2)));
};

const getRandomPointOnQuadrilateral = (
  p1: Point,
  p2: Point,
  p3: Point,
  p4: Point
): Point => {
  const lines: [Point, Point][] = [
    [p1, p2],
    [p2, p3],
    [p3, p4],
    [p4, p1],
  ];

  const linesLen = lines.map((v) => getDistanceBetweenPoints(v[0], v[1]));

  const randomRes = getRandomNumber(
    0,
    linesLen.reduce((a, b) => a + b)
  );

  let lenStart = 0;
  for (let li = 0; li < lines.length; li++) {
    const end = lenStart + linesLen[li];
    if (end < randomRes) {
      lenStart += linesLen[li];
      continue;
    }
    const progress = range(lenStart, end, 0, 1, randomRes);

    const line = lines[li];

    return interpolatePoints(...lines[li], progress);

    const x = (line[0].x - line[1].x) * progress + line[1].x;
    const y = (line[0].y - line[1].y) * progress + line[1].y;

    return { x, y };
  }

  return { x: screenWidth.value / 2, y: screenHeight.value / 2 };
};

const generateParticles = (secFromLast: number) => {
  const rawCount = secFromLast * PPS.value;

  const count =
    rawCount > 1 ? Math.ceil(rawCount) : Math.random() < rawCount ? 1 : 0;

  const bXv = -rotationX.value;
  const bYv = rotationY.value;

  for (let i = 0; i < count; i++) {
    const { x, y } = getRandomPointOnQuadrilateral(
      cardPoints.value.tl,
      cardPoints.value.tr,
      cardPoints.value.br,
      cardPoints.value.bl
    );
    particles.push({
      x,
      y,
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
