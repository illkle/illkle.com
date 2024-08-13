<template>
  <div
    @mousedown="() => (spawnCap = 20000)"
    @mouseup="() => (spawnCap = 10)"
    @mouseleave="() => (spawnCap = 10)"
    ref="canvasP"
    class="absolute top-0 overflow-hidden opacity-100 bg-red-300"
  ></div>
</template>

<script setup lang="ts">
import FragPosition from './sim_fragPosition.glsl';
import FragVelocity from './sim_fragVelocity.glsl';
import * as THREE from 'three';
import FragmentShader from './part_fragmentShader.glsl';
import VertexShader from './part_vertexShader.glsl';
import { GPUComputationRenderer } from 'three/examples/jsm/Addons.js';

const { screenWidth, screenHeight } = useScreenSize();
const { scroll } = useScroll();

const FST = computed(() => range(0, screenHeight.value, 0, 100, scroll.value));

const canvasP = ref<HTMLDivElement | null>(null);

let renderer: THREE.WebGLRenderer;
let scene: THREE.Scene | null;
let camera: THREE.PerspectiveCamera | null;

const spawnCap = ref(10);

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

  const count = 100000;

  const texSize = Math.ceil(Math.sqrt(count));

  const gpuCompute = new GPUComputationRenderer(texSize, texSize, renderer);

  const dtPosition = gpuCompute.createTexture();
  const dtVelocity = gpuCompute.createTexture();

  const velocityVariable = gpuCompute.addVariable('textureVelocity', FragVelocity, dtVelocity);
  const positionVariable = gpuCompute.addVariable('texturePosition', FragPosition, dtPosition);

  gpuCompute.setVariableDependencies(velocityVariable, [positionVariable, velocityVariable]);
  gpuCompute.setVariableDependencies(positionVariable, [positionVariable, velocityVariable]);

  const positionUniforms = positionVariable.material.uniforms;
  const velocityUniforms = velocityVariable.material.uniforms;

  positionUniforms['time'] = { value: 0.0 };
  positionUniforms['delta'] = { value: 0.0 };
  velocityUniforms['time'] = { value: 1.0 };
  velocityUniforms['delta'] = { value: 0.0 };

  velocityVariable.wrapS = THREE.RepeatWrapping;
  velocityVariable.wrapT = THREE.RepeatWrapping;
  positionVariable.wrapS = THREE.RepeatWrapping;
  positionVariable.wrapT = THREE.RepeatWrapping;

  gpuCompute.init();

  const posAttr = new AttributeGenerator(count, 3, ([x, y]: number[]) => [x, y, 0], [0, 0]);

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
            ]),
            0,
          ],
    true
  );

  const ttl = new THREE.BufferAttribute(new Float32Array([...Array(count)].map(() => 0)), 1);
  const timeBorn = new THREE.BufferAttribute(new Float32Array([...Array(count)].map(() => 0)), 1);

  const velAttr = new AttributeGenerator(count, 3, () => [0, 0, 0]);

  // Offset, scale, dist
  const attractions = new AttributeGenerator(count, 3, () => [15, 10, 10]);

  particlesGeo.setAttribute('position', posAttr.ba);
  particlesGeo.setAttribute('aSize', sizeAttr.ba);
  particlesGeo.setAttribute('aVelocity', velAttr.ba);
  particlesGeo.setAttribute('aTimeWhenDead', ttl);
  particlesGeo.setAttribute('aTimeBorn', timeBorn);
  particlesGeo.setAttribute('aAttractions', attractions.ba);

  let startFrom = 0;
  let lastClock: number | null = null;

  const itemTimeCost = 1 / count;

  const getInd = (v: number) => {
    return Math.ceil((v - Math.floor(v)) / itemTimeCost);
  };

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
    }

    const percentOfSecond = (finishAt - startFrom) / count;
    const allowedToSpawn = spawnCap.value * percentOfSecond;
    let spawned = 0;

    if (allowedToSpawn < 1) {
      if (Math.random() > allowedToSpawn) {
        return;
      }
    }

    for (let i = startFrom; i < finishAt && spawned < allowedToSpawn; i++) {
      if (ttl.array[i] > clock) continue;

      spawned++;
      if (!setUpdate) {
        [posAttr.ba, sizeAttr.ba, velAttr.ba, ttl, timeBorn, attractions.ba].forEach((v) => {
          v.needsUpdate = true;
        });
        setUpdate = true;
      }

      /*
      const { x, y } = getRandomPointOnQuadrilateral(
        cardPoints.value.tl,
        cardPoints.value.tr,
        cardPoints.value.br,
        cardPoints.value.bl
      );
      */
      posAttr.updateIndex(i, [cursorX - (camera?.position.y || 0), cursorY - (camera?.position.y || 0)]);
      velAttr.updateIndex(i);
      sizeAttr.updateIndex(i);

      ttl.array[i] = clock + getRandomNumber(3, 7);
      timeBorn.array[i] = clock;
    }

    startFrom = toSetAsStart;
    lastClock = clock;
  };

  const particleMaterial = new THREE.ShaderMaterial({
    vertexShader: VertexShader,
    fragmentShader: FragmentShader,
    transparent: true,
    vertexColors: true,

    depthWrite: false,
    uniforms: {
      uTexture: {
        value: new THREE.TextureLoader().load('_nuxt/public/textTest.jpg'),
      },
      uTextureX: {
        value: new THREE.Vector2(-100, 100),
      },
      uTextureY: {
        value: new THREE.Vector2(-100, 100),
      },
      uScreenSize: {
        value: renderer.getSize(new THREE.Vector2()),
      },
      uSize: { value: renderer.getPixelRatio() },
      uTime: { value: 0 },
      uLightPos: { value: new THREE.Vector2(0, 50) },

      uPosition: {
        value: gpuCompute.getCurrentRenderTarget(positionVariable).texture,
      },
      uVelocity: {
        value: gpuCompute.getCurrentRenderTarget(velocityVariable).texture,
      },
    },
  });

  const particles = new THREE.Points(particlesGeo, particleMaterial);
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

  let lastTs = 0;

  const animationLoop: FrameRequestCallback = (timestamp) => {
    if (!scene || !camera) return;

    const elapsedTime = clock.getElapsedTime();
    const delta = clock.getDelta();

    positionUniforms['time'].value = elapsedTime;
    positionUniforms['delta'].value = delta;
    velocityUniforms['time'].value = elapsedTime;
    velocityUniforms['delta'].value = delta;

    particleMaterial.uniforms.uTime.value = elapsedTime;

    raycaster.setFromCamera(pointer, camera);
    const res = new THREE.Vector3();
    raycaster.ray.intersectPlane(thePlane, res);

    updateStuff(elapsedTime, res.x, res.y);
    gpuCompute.compute();

    particleMaterial.uniforms.uPosition.value = gpuCompute.getCurrentRenderTarget(positionVariable).texture;
    particleMaterial.uniforms.uVelocity.value = gpuCompute.getCurrentRenderTarget(velocityVariable).texture;

    renderer.render(scene, camera);
  };

  renderer.setAnimationLoop(animationLoop);
});

const P_SPREAD = 30;
const P_MULT = 1.5;
</script>
