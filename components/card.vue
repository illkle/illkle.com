<template>
  <div class="" :style="{}">
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
        class="relative overflow-hidden opacity-100 rounded-lg"
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

    <div
      ref="canvasP"
      class="absolute top-0 overflow-hidden pointer-events-none opacity-100 bg-red-300"
    ></div>
  </div>
</template>
<script setup lang="ts">
import * as THREE from 'three';
import FragmentShader from './fragmentShader.glsl';
import VertexShader from './vertexShader.glsl';

const { screenWidth, screenHeight } = useScreenSize();
const { scroll } = useScroll();

const FST = computed(() => range(0, screenHeight.value, 0, 100, scroll.value));

const canvasP = ref<HTMLDivElement | null>(null);

let renderer: THREE.WebGLRenderer;
let scene: THREE.Scene | null;
let camera: THREE.PerspectiveCamera | null;

onMounted(() => {
  if (!canvasP.value) return;
  scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(
    75,
    document.documentElement.clientWidth /
      document.documentElement.clientHeight,
    0.1,
    1000
  );

  renderer = new THREE.WebGLRenderer();

  renderer.setSize(
    document.documentElement.clientWidth,
    document.documentElement.clientHeight
  );
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  canvasP.value.appendChild(renderer.domElement);

  window.addEventListener('resize', () => {
    if (!camera) return;
    renderer.setSize(
      document.documentElement.clientWidth,
      document.documentElement.clientHeight
    );
    camera.aspect =
      document.documentElement.clientWidth /
      document.documentElement.clientHeight;
    camera.updateProjectionMatrix();
  });

  camera.position.z = 100;

  // Geo

  const particlesGeo = new THREE.BufferGeometry();

  const count = 100000;

  const positions = new THREE.BufferAttribute(
    new Float32Array([...Array(count * 3)].map(() => 0)),
    3
  );
  const sizes = new THREE.BufferAttribute(
    new Float32Array([...Array(count)].map(() => getRandomNumber(1000, 3000))),
    1
  );
  const ttl = new THREE.BufferAttribute(
    new Float32Array([...Array(count)].map(() => 0.2)),
    1
  );
  const timeBorn = new THREE.BufferAttribute(
    new Float32Array([...Array(count)].map(() => 0)),
    1
  );
  const velocities = new THREE.BufferAttribute(
    new Float32Array([...Array(count * 3)].map(() => getRandomNumber(-50, 50))),
    3
  );

  const attractions = new THREE.BufferAttribute(
    new Float32Array([...Array(count * 3)].map(() => 0)),
    3
  );

  particlesGeo.setAttribute('position', positions);
  particlesGeo.setAttribute('aSize', sizes);
  particlesGeo.setAttribute('aVelocity', velocities);
  particlesGeo.setAttribute('aTimeWhenDead', ttl);
  particlesGeo.setAttribute('aTimeBorn', timeBorn);
  particlesGeo.setAttribute('aAttractions', timeBorn);

  let startFrom = 0;
  let lastClock: number | null = null;

  const itemTimeCost = 1 / count;

  const getInd = (v: number) => {
    return Math.ceil((v - Math.floor(v)) / itemTimeCost);
  };

  const updateStuff = (clock: number) => {
    let setUpdate = false;

    if (!lastClock) {
      lastClock = clock;
      return;
    }

    const bXv = -rotationX.value;
    const bYv = -rotationY.value;

    let finishAt = getInd(lastClock);
    let toSetAsStart = finishAt;

    if (finishAt < startFrom) {
      finishAt = count;
      toSetAsStart = 0;
    }

    for (let i = startFrom; i < finishAt; i++) {
      if (ttl.array[i] > clock) continue;
      const to = i * 3;

      if (!setUpdate) {
        positions.needsUpdate = true;
        velocities.needsUpdate = true;
        sizes.needsUpdate = true;
        ttl.needsUpdate = true;
        timeBorn.needsUpdate = true;
        attractions.needsUpdate = true;
        setUpdate = true;
      }

      const { x, y } = getRandomPointOnQuadrilateral(
        cardPoints.value.tl,
        cardPoints.value.tr,
        cardPoints.value.br,
        cardPoints.value.bl
      );

      positions.array[to] = (x - screenWidth.value / 2) * 0.12;
      positions.array[to + 1] = (y - screenHeight.value / 2) * 0.12;
      positions.array[to + 2] = 0;

      velocities.array[to] =
        getRandomNumber(bXv - P_SPREAD, bXv + P_SPREAD) * P_MULT;
      velocities.array[to + 1] =
        getRandomNumber(bYv - P_SPREAD, bYv + P_SPREAD) * P_MULT;
      velocities.array[to + 2] = 0;

      sizes.array[i] = Math.max(
        0,
        Math.random() > 0.98
          ? getRandomNumber2(-5000, 5000)
          : getRandomNumber2(-500, 500)
      );

      attractions.array[to] = getRandomNumber(-1, 1);
      attractions.array[to + 1] = getRandomNumber(-1, 1);
      attractions.array[to + 2] = 1000;

      ttl.array[i] = clock + getRandomNumber(3, 7);
      timeBorn.array[i] = clock;
    }

    startFrom = toSetAsStart;
    lastClock = clock;
  };

  const material2 = new THREE.ShaderMaterial({
    vertexShader: VertexShader,
    fragmentShader: FragmentShader,
    blending: THREE.AdditiveBlending,
    vertexColors: true,
    depthWrite: false,
    uniforms: {
      uSize: { value: renderer.getPixelRatio() },
      uTime: { value: 0 },
    },
  });

  const geometry = new THREE.PlaneGeometry(1, 1, 32, 32);
  const particles = new THREE.Points(particlesGeo, material2);
  scene.add(particles);
  const mesh = new THREE.Mesh(geometry, material2);
  scene.add(mesh);

  const clock = new THREE.Clock();
  clock.start();
  const animationLoop: FrameRequestCallback = (timestamp) => {
    if (!scene || !camera) return;

    const elapsedTime = clock.getElapsedTime();
    // Update material
    material2.uniforms.uTime.value = elapsedTime;

    updateStuff(elapsedTime);

    renderer.render(scene, camera);
  };

  renderer.setAnimationLoop(animationLoop);
});

const P_SPREAD = 40;
const P_MULT = 1;

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

const PPS = ref(300);

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
