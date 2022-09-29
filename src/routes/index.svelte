<script context="module" lang="ts">
	export const prerender = true;
</script>

<script lang="ts">
	import * as THREE from 'three';

	import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
	import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
	import { RectAreaLightHelper } from 'three/examples/jsm/helpers/RectAreaLightHelper';
	import { onMount } from 'svelte';

	let divFor3d: HTMLElement;

	const scene = new THREE.Scene();

	const mainMaterial = new THREE.MeshStandardMaterial({ color: 'rgb(200,200,200)' });

	const loader = new GLTFLoader();

	const material = new THREE.MeshPhysicalMaterial({ color: 'rgb(150,255,50)' });

	let light3 = new THREE.RectAreaLight('white', 20, 5, 5);
	light3.position.set(-15, 7, 8);
	light3.lookAt(0, 0, 0);

	const helper = new RectAreaLightHelper(light3);

	scene.add(light3);

	scene.add(helper);

	const ambitent = new THREE.AmbientLight('white', 0.1);
	scene.add(ambitent);

	onMount(() => {
		const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });

		const camera = new THREE.PerspectiveCamera(
			60,
			window.innerWidth / window.innerHeight,
			0.1,
			1000
		);

		camera.position.y = 25;

		renderer.setSize(window.innerWidth, window.innerHeight);

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

<svelte:head>
	<title>ze kel | home</title>
</svelte:head>

<section class="h-full flex flex-col">
	<div class="absolute left-0 top-0 z-0" bind:this={divFor3d} />
</section>

<style>
</style>
