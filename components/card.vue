<template>
  <div class="" :style="{}">
    <div
      ref="cardRef"
      class="flex z-10 fixed"
      :style="{
        perspective: '900px',
        left: '50%',
        top: `${range(0, 100, 50, 0, FST)}%`,
        transform: `translate(-50%, ${range(0, 100, -50, 0, FST)}%)`,
      }"
    >
      <div
        :style="{
          transform: rotationStyle,
        }"
        class="relative overflow-hidden opacity-0 rounded-lg"
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

    <div ref="canvasP" class="absolute top-0 overflow-hidden pointer-events-none opacity-100 bg-red-300"></div>
  </div>
</template>
<script setup lang="ts">
import * as THREE from 'three';
import FragmentShader from './fragmentShader.glsl';
import VertexShader from './vertexShader.glsl';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

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
    document.documentElement.clientWidth / document.documentElement.clientHeight,
    0.1,
    1000
  );

  renderer = new THREE.WebGLRenderer();

  renderer.setSize(document.documentElement.clientWidth, document.documentElement.clientHeight);
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  canvasP.value.appendChild(renderer.domElement);

  window.addEventListener('resize', () => {
    if (!camera) return;
    renderer.setSize(document.documentElement.clientWidth, document.documentElement.clientHeight);
    camera.aspect = document.documentElement.clientWidth / document.documentElement.clientHeight;
    camera.updateProjectionMatrix();
  });

  camera.position.z = 100;

  //const controls = new OrbitControls(camera, document.documentElement);
  //controls.update();

  // Geo

  const particlesGeo = new THREE.BufferGeometry();

  const count = 50000;

  const posAttr = new AttributeGenerator(
    count,
    3,
    ([x, y]: number[]) => [
      x,
      y,
      //  (x - screenWidth.value / 2) * 0.12,
      //(y - screenHeight.value / 2) * 0.12,
      0, //getRandomNumber(0, 60),
    ],
    [0, 0]
  );

  const sizeAttr = new AttributeGenerator(
    count,
    2,
    (makeZero?: boolean) =>
      makeZero
        ? [0, 0]
        : [
            customRandomness([
              [0, 100, 0.2],
              [500, 1000, 0.7],
              [1000, 4000, 0.9],
              [4000, 7000, 0.95],
              [7000, 8000, 1],
            ]) * 1.5,
            0,
          ],
    true
  );

  const ttl = new THREE.BufferAttribute(new Float32Array([...Array(count)].map(() => getRandomNumber(0, 7))), 1);
  const timeBorn = new THREE.BufferAttribute(new Float32Array([...Array(count)].map(() => 0)), 1);

  const velAttr = new AttributeGenerator(count, 3, () => [
    customRandomness([
      [-rotationX.value - P_SPREAD, -rotationX.value + P_SPREAD, 0.9],
      [-P_SPREAD * 2, P_SPREAD * 2, 1],
    ]),
    customRandomness([
      [-rotationY.value - P_SPREAD, -rotationY.value + P_SPREAD, 0.9],
      [-P_SPREAD * 2, P_SPREAD * 2, 1],
    ]),
    0,
  ]);

  const attractions = new THREE.BufferAttribute(new Float32Array([...Array(count * 3)].map(() => 0)), 3);

  particlesGeo.setAttribute('position', posAttr.ba);
  particlesGeo.setAttribute('aSize', sizeAttr.ba);
  particlesGeo.setAttribute('aVelocity', velAttr.ba);
  particlesGeo.setAttribute('aTimeWhenDead', ttl);
  particlesGeo.setAttribute('aTimeBorn', timeBorn);
  particlesGeo.setAttribute('aAttractions', timeBorn);

  let startFrom = 0;
  let lastClock: number | null = null;

  const itemTimeCost = 1 / count;

  const getInd = (v: number) => {
    return Math.ceil((v - Math.floor(v)) / itemTimeCost);
  };

  let updatedThisSecond = 0;
  const updateStuff = (clock: number, cursorX: number, cursorY: number) => {
    let setUpdate = false;

    if (!lastClock) {
      lastClock = clock;
      return;
    }

    let finishAt = getInd(lastClock);
    let toSetAsStart = finishAt;

    if (finishAt < startFrom) {
      finishAt = count;
      toSetAsStart = 0;
      updatedThisSecond = 0;
    }

    for (let i = startFrom; i < finishAt; i++) {
      if (ttl.array[i] > clock) continue;

      if (!setUpdate) {
        [posAttr.ba, sizeAttr.ba, velAttr.ba, ttl, timeBorn, attractions].forEach((v) => {
          v.needsUpdate = true;
        });
        setUpdate = true;
      }

      updatedThisSecond++;

      const { x, y } = getRandomPointOnQuadrilateral(
        cardPoints.value.tl,
        cardPoints.value.tr,
        cardPoints.value.br,
        cardPoints.value.bl
      );
      posAttr.updateIndex(i, [cursorX, cursorY]);
      velAttr.updateIndex(i);
      sizeAttr.updateIndex(i);

      ttl.array[i] = clock + getRandomNumber(3, 7);
      timeBorn.array[i] = clock;
    }

    startFrom = toSetAsStart;
    lastClock = clock;
  };

  const material2 = new THREE.ShaderMaterial({
    vertexShader: VertexShader,
    fragmentShader: FragmentShader,
    transparent: true,
    vertexColors: true,
    depthWrite: false,
    uniforms: {
      uSize: { value: renderer.getPixelRatio() },
      uTime: { value: 0 },
      uLightPos: { value: new THREE.Vector2(0, 50) },
    },
  });
  const particles = new THREE.Points(particlesGeo, material2);
  scene.add(particles);

  const material = new THREE.MeshBasicMaterial({
    color: new THREE.Color(255, 255, 0),
    opacity: 0,
    transparent: true,
    side: THREE.DoubleSide,
  });

  const hiddenPlay = new THREE.PlaneGeometry(1000, 1000, 1, 1);
  const hP = new THREE.Mesh(hiddenPlay, material);
  // hP.translateZ(-100);
  scene.add(hP);

  // scene.background = new THREE.Color(0.2, 0.2, 0.2);

  const clock = new THREE.Clock();
  clock.start();

  const raycaster = new THREE.Raycaster();
  const thePlane = new THREE.Plane(new THREE.Vector3(0, 0, 1));
  const pointer = new THREE.Vector2();

  function onPointerMove(event: any) {
    pointer.x = (event.clientX / window.innerWidth) * 2 - 1;
    pointer.y = -(event.clientY / window.innerHeight) * 2 + 1;
  }
  addEventListener('mousemove', onPointerMove);

  const animationLoop: FrameRequestCallback = (timestamp) => {
    if (!scene || !camera) return;

    const elapsedTime = clock.getElapsedTime();
    // Update material
    material2.uniforms.uTime.value = elapsedTime;

    raycaster.setFromCamera(pointer, camera);
    const res = new THREE.Vector3();
    raycaster.ray.intersectPlane(thePlane, res);

    updateStuff(elapsedTime, res.x, res.y);

    renderer.render(scene, camera);
  };

  renderer.setAnimationLoop(animationLoop);
});

const P_SPREAD = 30;
const P_MULT = 1.5;

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

onMounted(() => {
  addEventListener('resize', updateCardPoint);
  addEventListener('mousemove', updateCardPoint);
  addEventListener('scroll', updateCardPoint);
});
</script>
