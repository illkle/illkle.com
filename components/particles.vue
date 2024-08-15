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
import FragInfo from './sim_fragInfo.glsl';
import FragPosition from './sim_fragPosition.glsl';
import FragVelocity from './sim_fragVelocity.glsl';
import FragRandom from './sim_fragRandom.glsl';
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

  const count = 50000;
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

  fillTexture(dtRandom, () => [
    Math.random(),
    Math.random(),
    0,
    customRandomness([
      [0, 100, 0.2],
      [500, 1000, 0.7],
      [1000, 4000, 0.9],
      [4000, 7000, 0.95],
      [7000, 8000, 1],
    ]),
  ]);
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

  const updateComputeUniforms = (time: number, delta: number, cursor: THREE.Vector2) => {
    vars.forEach((v) => {
      const uni = v.material.uniforms;
      uni['time'] = { value: time };
      uni['delta'] = { value: delta };
      uni['cursor'] = { value: cursor };
    });
  };

  updateComputeUniforms(0.0, 0.0, new THREE.Vector2(0, 0));

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
      uCursor: {
        value: new THREE.Vector2(),
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

  let lastTs = 0;

  const animationLoop: FrameRequestCallback = (timestamp) => {
    if (!scene || !camera) return;

    const elapsedTime = clock.getElapsedTime();
    const delta = elapsedTime - lastTs;
    lastTs = elapsedTime;

    raycaster.setFromCamera(pointer, camera);
    const res = new THREE.Vector3();
    raycaster.ray.intersectPlane(thePlane, res);

    updateComputeUniforms(elapsedTime, delta, new THREE.Vector2(res.x, res.y));

    gpuCompute.compute();

    particleMaterial.uniforms.uCursor.value = pointer;
    particleMaterial.uniforms.uTime.value = elapsedTime;
    particleMaterial.uniforms.uPosition.value = gpuCompute.getCurrentRenderTarget(positionVariable).texture;
    particleMaterial.uniforms.uVelocity.value = gpuCompute.getCurrentRenderTarget(velocityVariable).texture;
    particleMaterial.uniforms.uInfo.value = gpuCompute.getCurrentRenderTarget(infoVariable).texture;
    particleMaterial.uniforms.uRandom.value = gpuCompute.getCurrentRenderTarget(randomVariable).texture;

    renderer.render(scene, camera);
  };

  renderer.setAnimationLoop(animationLoop);
});
</script>
