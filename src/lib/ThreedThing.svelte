<script lang="ts">
	import * as THREE from 'three';

	import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
	import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
	import { RectAreaLightHelper } from 'three/examples/jsm/helpers/RectAreaLightHelper';
	import { onMount } from 'svelte';
	import { Layers } from 'three';

	let divFor3d: HTMLElement;

	const scene = new THREE.Scene();

	const mainMaterial = new THREE.MeshStandardMaterial({ color: 'rgb(240,240,240)' });

	const loader = new GLTFLoader();

	let light1 = new THREE.RectAreaLight('white', 4, 10, 10);
	light1.position.set(10, 10, -4);
	light1.lookAt(0, 0, 0);
	light1.castShadow = true;
	const helper1 = new RectAreaLightHelper(light1);
	scene.add(light1);
	//scene.add(helper1);

	let light2 = new THREE.AmbientLight('white', 0.5);
	scene.add(light2);

	let light3 = new THREE.RectAreaLight('white', 10, 20, 20);
	light3.position.set(-25, 7, 8);
	light3.lookAt(0, 0, 0);
	light3.castShadow = true;
	const helper3 = new RectAreaLightHelper(light3);
	scene.add(light3);
	//scene.add(helper3);

	const ambitent = new THREE.AmbientLight('white', 0.1);
	scene.add(ambitent);

	onMount(() => {
		const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
		renderer.toneMapping = THREE.ACESFilmicToneMapping;
		renderer.physicallyCorrectLights = true;

		const rect = divFor3d.getBoundingClientRect();

		console.log('rectw', rect.height);

		const camera = new THREE.PerspectiveCamera(60, rect.width / rect.height, 0.1, 1000);

		camera.position.y = 25;

		renderer.setSize(rect.width, rect.height);

		divFor3d.appendChild(renderer.domElement);

		const controls = new OrbitControls(camera, renderer.domElement);
		controls.update();

		loader.load('src/assets/ze_kel.glb', function onload(file) {
			const sign = file.scene.children[0];

			sign.scale.set(8, 8, 8);
			sign.position.set(0, 0, 1.2);

			//@ts-expect-error
			sign.material = mainMaterial;

			scene.add(sign);
		});

		function animate() {
			requestAnimationFrame(animate);
			renderer.render(scene, camera);
		}
		animate();
	});
</script>

<div bind:this={divFor3d} class=" h-full" />
