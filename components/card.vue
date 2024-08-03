<template>
  <div
    class="flex h-screen w-screen overflow-hidden items-center justify-center"
    :style="{}"
  >
    <div
      ref="cardRef"
      class="flex z-10 fixed"
      :style="{
        perspective: '300px',
        left: '50%',
        top: `${range(0, 100, 50, 0, FST)}%`,
        transform: `translate(-50%, ${range(0, 100, -50, 0, FST)}%)`,
      }"
    >
      <div
        :style="{
          transform: rotationStyle,
        }"
        class="relative overflow-hidden"
      >
        <div class="w-full h-full flex flex-col relative box-border">
          <!--Card overlays-->
          <img
            src="/public/over1.jpg"
            class="absolute left-1/2 top-1/2 w-[1500px] h-[1500px] z-20 max-w-[unset] pointer-events-none"
            :style="{
              opacity: range(0, 100, 50, 0, FST),
              transform: `translateX(calc(-50% + ${overlay1X}%)) translateY(calc(-50% + ${overlay1Y}%))`,
            }"
          />

          <!--Card position points to grab it's coordinates relative to screen-->
          <div ref="cardTL" class="absolute top-1 left-1"></div>
          <div ref="cardTR" class="absolute top-1 right-1"></div>
          <div ref="cardBR" class="absolute bottom-1 right-1"></div>
          <div ref="cardBL" class="absolute bottom-1 left-1"></div>

          <!--Card Inner content-->
          <CardContent />
        </div>
      </div>
    </div>

    <div v-if="false">
      <div>Frametime: {{ frameTime.toFixed(6) }}</div>

      <div>Time budget: {{ (1000 / fps).toFixed(4) }}</div>
      <div>FPS {{ fps.toFixed(0) }} (approx)</div>

      <input v-model="PPS" class="bg-neutral-950" type="number" />

      <button class="bg-neutral-50" @click="() => (flipped = false)">
        PLAY PAUSE
      </button>
    </div>

    <canvas
      ref="canvasL"
      class="absolute top-0 left-0 pointer-events-none opacity-[1] mix-2blend-color-dodge z-[1]"
    ></canvas>
    <canvas
      ref="canvasP"
      class="absolute top-0 left-0 pointer-events-none opacity-100"
    ></canvas>
  </div>
</template>
<script setup lang="ts">
const { screenWidth, screenHeight } = useScreenSize();
const { scroll } = useScroll();

const FST = computed(() => range(0, screenHeight.value, 0, 100, scroll.value));

const canvasP = ref<HTMLCanvasElement | null>(null);
const canvasL = ref<HTMLCanvasElement | null>(null);

const contextP = useCanvasContext(canvasP, screenWidth, screenHeight);
const contextL = useCanvasContext(canvasL, screenWidth, screenHeight);

// Card transform

const cardRef = ref<HTMLElement>();

const flipped = ref(false);

const { mouseX, mouseY, hasMouse } = useMousePos();

const mousePercentX = computed(() =>
  hasMouse.value ? range(0, screenWidth.value, 0, 100, mouseX.value) : 50
);
const mousePercentY = computed(() =>
  hasMouse.value ? range(0, screenHeight.value, 0, 100, mouseY.value) : 50
);

const mouseDistance = computed(() =>
  hasMouse.value
    ? Math.abs(mousePercentX.value - 50) + Math.abs(mousePercentY.value - 50)
    : 0
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

onMounted(() => {
  addEventListener('resize', updateCardPoint);
  addEventListener('mousemove', updateCardPoint);
  addEventListener('scroll', updateCardPoint);
});

// Main loop
const isGeneratingParticles = ref(true);

const playing = ref(false);

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

// Pause animation when its not needed

const stopAnimation = () => {
  playing.value = false;
};

const startAnimation = () => {
  playing.value = true;
  nextTick(() => {
    requestAnimationFrame(renderLoop);
  });
};

const playOnVisible = () => {
  if (document.hidden) {
    stopAnimation();
  } else if (!playing.value) {
    startAnimation();
  }
};

onMounted(() => {
  startAnimation();
  document.addEventListener('visibilitychange', playOnVisible);
});

onUnmounted(() => {
  document.removeEventListener('visibilitychange', playOnVisible);
});

// Disable animation when user scrolled off, restore it when he scrolls back
watch([FST], (v) => {
  if (v[0] >= 100) {
    stopAnimation();
  } else if (!playing.value) {
    startAnimation();
  }
});

// Particles
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
  const color = range(0, 100, 255, 100, mouseDistance.value);
  //const color = 255;
  ctx.fillStyle = `rgb(${color}, ${color}, ${color})`;
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

const drawLight = (ctx: CanvasRenderingContext2D) => {
  const fromMouseToCard = [
    cardPoints.value.tl,
    cardPoints.value.tr,
    cardPoints.value.br,
    cardPoints.value.bl,
  ].map((v) => {
    return { from: { x: mouseX.value, y: mouseY.value }, to: v };
  });

  const lFactor = 4;
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
    ctx.moveTo(a.from.x, a.from.y);

    ctx.strokeStyle = 'rgb(50,50,50)';
    ctx.stroke();
  }
};

const frameUpdate = (secFromLast: number) => {
  if (!contextP.value || !contextL.value) return;
  if (isGeneratingParticles.value) {
    generateParticles(secFromLast);
  }
  simulateParticles(secFromLast);
  clearScreen(contextP.value);
  drawParticles(contextP.value);
  // drawInfo(contextP.value);
  //clearScreen(contextL.value);
  //drawLight(contextL.value);
};

const clearScreen = (ctx: CanvasRenderingContext2D) => {
  ctx.clearRect(0, 0, screenWidth.value, screenHeight.value);
};

const PPS = ref(300);

const P_SPREAD = 20;
const P_MULT = 15;

const generateParticles = (secFromLast: number) => {
  const rawCount =
    secFromLast * range(0, 100, 25, PPS.value, mouseDistance.value);

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
      ttl: 100,
      size:
        Math.random() > 0.9 ? getRandomNumber(5, 15) : getRandomNumber(1, 5),
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
