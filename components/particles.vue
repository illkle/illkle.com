<template>
  <div ref="letterWrapper" class="absolute top-1/2 -translate-y-1/2 left-1/2 max-md:-translate-x-1/2 z-50">
    <svg class="w-[400px]" viewBox="0 0 101 109" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path
        ref="letterRef"
        d="M0.782227 107V0.5H30.1822V42.65L62.7322 0.5H96.0322L58.6822 48.05L98.1322 107H65.5822L39.4822 67.1L30.1822 78.5V107H0.782227Z"
      />
    </svg>

    <div
      class="absolute top-0 left-0 w-10 h-10 bg-red-500 opacity-0"
      :style="`transform: translate(${onLetterPosition.x}px, ${onLetterPosition.y}px)`"
    ></div>
  </div>

  <div
    class="absolute opacity-0 hover:opacity-100 transition-opacity bg-neutral-950 p-2 rounded-tl-xl bottom-0 right-0 z-20 flex opacity flex-col"
  >
    <div v-for="(el, i) in controls">
      <input v-model.number="controls[i]" type="number" class="w-20 bg-zinc-950 text-center" />
      {{ i }}
    </div>
  </div>
  <div class="opacity-0 absolute top-1/2 left-[80px] flex items-center justify-center z-10 -translate-y-1/2">
    <h2 class="text-[128px] font-black">ZE KEL</h2>
  </div>
  <div ref="canvasP" class="absolute top-0 overflow-hidden opacity-100"></div>
</template>

<script setup lang="ts">
import FragInfo from './sim_fragInfo.glsl';
import FragPosition from './sim_fragPosition.glsl';
import FragVelocity from './sim_fragVelocity.glsl';
import FragRandom from './sim_fragRandom.glsl';
import * as THREE from 'three';
import FragmentShader from './part_fragmentShader.glsl';
import VertexShader from './part_vertexShader.glsl';
import { GPUComputationRenderer } from 'three/examples/jsm/Addons.js';
import anime from 'animejs/lib/anime.es.js';
import { useElementBounding, useWindowSize } from '@vueuse/core';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const { width, height } = useWindowSize();

const canvasP = ref<HTMLDivElement | null>(null);

let renderer: THREE.WebGLRenderer;
let scene: THREE.Scene | null;
let camera: THREE.PerspectiveCamera | null;

const controls = ref({
  uBaseMult: 0.5,
  uBaseTimeScale: 10,

  // Primary Noise
  uVelPositionScale: 0.2,
  uVelRandomScale: 0.1,
  uVelTimeScale: 1,
  uVelMult: 2,

  uNoiseScale: 0.1,

  // Secondary noise
  uVel2PositionScale: 0.2,
  uVel2RandomScale: 0.1,
  uVel2TimeScale: 1.3,
  uVel2Mult: 2,
  // Secondary noise decreases from 1 to 0 in this size range
  uVel2SizeLowerBound: 3000,
  uVel2SizeUpperBound: 4000,

  uNoise2Scale: 0.3,

  uSizeMod: 3,
  uLightPosX: 0,
  uLightPosY: 200,
  uLightPower: 500,
  uShadowRound: 0.2,
  uShadowDirectional: 0.5,
});

const canSave = ref(false);

const letterWrapper = ref<HTMLDivElement | null>(null);

const letterWrapperDims = useElementBounding(letterWrapper);

const letterRef = ref<HTMLDivElement | null>(null);

const onLetterPosition = ref({ x: 0, y: 0, rotate: 0, percentage: 0, pathLen: 0 });

const letterSLen = 20;
const letterDashArray = computed(() => {
  const { pathLen } = onLetterPosition.value;

  if (!pathLen) return '';

  return `${letterSLen} ${pathLen - letterSLen}`;
});

const letterDashOffset = computed(() => {
  const { pathLen, percentage } = onLetterPosition.value;

  return -1 * pathLen * percentage;
});

onMounted(() => {
  const path = anime.path(letterRef.value);

  const plen = path('').totalLength;

  onLetterPosition.value.pathLen = plen;
  console.log(plen);

  //letterRef.value?.setAttribute('stroke-dasharray', `${plen / 2} ${plen / 2}`);

  anime({
    targets: onLetterPosition.value,
    x: path('x'),
    y: path('y'),
    percentage: 1,
    rotate: path('angle'),
    easing: 'linear',
    duration: 8000,
    loop: true,
  });
});

onMounted(() => {
  const res = localStorage.getItem('particleSimControls');

  if (res) {
    const parsed = JSON.parse(res);

    if (typeof parsed === 'object') {
      Object.keys(controls.value).forEach((k) => {
        if (parsed[k] && !Number.isNaN(Number(parsed[k]))) {
          // @ts-ignore
          controls.value[k] = Number(parsed[k]);
        }
      });
    }
  }
  canSave.value = true;
});

watchEffect(() => {
  if (!canSave.value) return;
  localStorage.setItem('particleSimControls', JSON.stringify(controls.value));
});

onMounted(() => {
  if (!canvasP.value) return;
  scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(
    75,
    document.documentElement.clientWidth / document.documentElement.clientHeight,
    0.1,
    1000
  );

  renderer = new THREE.WebGLRenderer({ alpha: true });

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

  const particlesGeo = new THREE.BufferGeometry();

  const count = 200;
  const PPS = count / 10;

  const texSize = Math.ceil(Math.sqrt(count));

  const gpuCompute = new GPUComputationRenderer(texSize, texSize, renderer);

  // To simulate particles on a gpu data is stored in textures.
  // Each texture is vec4 with the folowing vals
  // dtRandom — random static seed for each particle random generation x3, particle size
  // dtVelocity — xyz velocities
  // dtInfo  — timeBorn, timeDead, isFreshSpawn
  // dtPositon — xyz position, blank

  const dtRandom = gpuCompute.createTexture();
  const dtPosition = gpuCompute.createTexture();
  const dtVelocity = gpuCompute.createTexture();
  const dtInfo = gpuCompute.createTexture();

  function easeInCubic(x: number): number {
    return x * x * x;
  }

  function easeInExpo(x: number): number {
    return x === 0 ? 0 : Math.pow(2, 10 * x - 10);
  }

  fillTexture(dtRandom, () => [Math.random(), Math.random(), Math.random(), customRandomness2(0, 5000, easeInExpo)]);
  fillTexture(dtInfo, (index) => {
    return [0, index / PPS, 1, 0];
  });

  const randomVariable = gpuCompute.addVariable('textureRandom', FragRandom, dtRandom);
  const velocityVariable = gpuCompute.addVariable('textureVelocity', FragVelocity, dtVelocity);
  const positionVariable = gpuCompute.addVariable('texturePosition', FragPosition, dtPosition);
  const infoVariable = gpuCompute.addVariable('textureInfo', FragInfo, dtInfo);

  gpuCompute.setVariableDependencies(randomVariable, [randomVariable]);
  gpuCompute.setVariableDependencies(velocityVariable, [
    randomVariable,
    positionVariable,
    velocityVariable,
    infoVariable,
  ]);
  gpuCompute.setVariableDependencies(infoVariable, [infoVariable, randomVariable]);
  gpuCompute.setVariableDependencies(positionVariable, [
    positionVariable,
    velocityVariable,
    randomVariable,
    infoVariable,
  ]);

  const vars = [randomVariable, velocityVariable, positionVariable, infoVariable];

  vars.forEach((v) => {
    v.material.defines.BOUNDS = texSize.toFixed(2);

    v.wrapS = THREE.RepeatWrapping;
    v.wrapT = THREE.RepeatWrapping;
  });

  const updateComputeUniforms = (time: number, delta: number, emitter: THREE.Vector3, emitDirection: THREE.Vector3) => {
    vars.forEach((v) => {
      const uni = v.material.uniforms;
      uni['time'] = { value: time };
      uni['delta'] = { value: delta };
      uni['uEmitter'] = { value: emitter };
      uni['uEmitTowards'] = { value: emitDirection };

      Object.keys(controls.value).forEach((key) => {
        // @ts-ignore
        uni[key] = { value: Number(controls.value[key]) };
      });
    });
  };

  updateComputeUniforms(0.0, 0.0, new THREE.Vector3(0, 0, 0), new THREE.Vector3(0, 0, 0));

  gpuCompute.init();

  const indexAttr = new AttributeGenerator(
    count,
    2,
    (_, i) => {
      if (!i) return [0, 0];
      const y = Math.floor(i / texSize);
      const x = i % texSize;

      return [x / texSize, y / texSize];
    },
    undefined
  );

  const posAttr = new AttributeGenerator(count, 3, () => [0, 0, 0]);

  particlesGeo.setAttribute('position', posAttr.ba);
  particlesGeo.setAttribute('aTarget', indexAttr.ba);

  const particleMaterial = new THREE.ShaderMaterial({
    vertexShader: VertexShader,
    fragmentShader: FragmentShader,
    transparent: true,
    vertexColors: true,

    depthWrite: false,
    uniforms: {
      uEmitter: {
        value: new THREE.Vector3(),
      },
      uScreenSize: {
        value: renderer.getSize(new THREE.Vector2()),
      },
      uSize: { value: renderer.getPixelRatio() },
      uTime: { value: 0 },
      uLightPos: { value: new THREE.Vector2(0, 50) },
      uLightPosX: { value: 0 },
      uLightPosY: { value: 0 },
      uLightPower: { value: 50 },
      uShadowDirectional: {
        value: 0.5,
      },
      uShadowRound: {
        value: 0.01,
      },
      uPosition: {
        value: gpuCompute.getCurrentRenderTarget(positionVariable).texture,
      },
      uVelocity: {
        value: gpuCompute.getCurrentRenderTarget(velocityVariable).texture,
      },
      uInfo: {
        value: gpuCompute.getCurrentRenderTarget(infoVariable).texture,
      },
      uRandom: {
        value: gpuCompute.getCurrentRenderTarget(randomVariable).texture,
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

  scene.add(hP);

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

  let elapsedTime = 0;

  const ctrls = new OrbitControls(camera, renderer.domElement);
  ctrls.update();

  const animationLoop: FrameRequestCallback = () => {
    console.log('frame');
    if (!scene || !camera) return;

    const delta = clock.getDelta();
    elapsedTime += delta;

    raycaster.setFromCamera(pointer, camera);
    const cursorInSpace = new THREE.Vector3();
    raycaster.ray.intersectPlane(thePlane, cursorInSpace);

    const radians = onLetterPosition.value.rotate * (Math.PI / 180);

    const tX = Math.cos(radians);
    const tY = Math.sin(radians);

    const letterEmitX = range(0, width.value, -1, 1, letterWrapperDims.left.value + onLetterPosition.value.x);
    const letterEmitY = range(0, height.value, 1, -1, letterWrapperDims.top.value + onLetterPosition.value.y);

    // -1 -1 left bottom 1 1 top right
    const emitCoords = new THREE.Vector2(letterEmitX, letterEmitY);

    raycaster.setFromCamera(emitCoords, camera);
    const emitFromInSpace = new THREE.Vector3();
    raycaster.ray.intersectPlane(thePlane, emitFromInSpace);

    updateComputeUniforms(elapsedTime, delta, new THREE.Vector3(0, 0, 0), new THREE.Vector3(0, 400, 200));

    gpuCompute.compute();

    // particleMaterial.uniforms.uLightPosX.value = cursorInSpace.x;
    // particleMaterial.uniforms.uLightPosY.value = cursorInSpace.y;
    particleMaterial.uniforms.uLightPosX.value = controls.value.uLightPosX;
    particleMaterial.uniforms.uLightPosY.value = controls.value.uLightPosY;
    particleMaterial.uniforms.uLightPower.value = controls.value.uLightPower;
    particleMaterial.uniforms.uShadowDirectional.value = controls.value.uShadowDirectional;
    particleMaterial.uniforms.uShadowRound.value = controls.value.uShadowRound;

    particleMaterial.uniforms.uTime.value = elapsedTime;
    particleMaterial.uniforms.uPosition.value = gpuCompute.getCurrentRenderTarget(positionVariable).texture;
    particleMaterial.uniforms.uVelocity.value = gpuCompute.getCurrentRenderTarget(velocityVariable).texture;
    particleMaterial.uniforms.uInfo.value = gpuCompute.getCurrentRenderTarget(infoVariable).texture;
    particleMaterial.uniforms.uRandom.value = gpuCompute.getCurrentRenderTarget(randomVariable).texture;

    renderer.render(scene, camera);
    requestAnimationFrame(animationLoop);
  };

  requestAnimationFrame(animationLoop);
});
</script>
