<script lang="ts">
	import Footer from '$lib/Footer.svelte';
	import Header from '$lib/Header.svelte';
	import '../app.css';
</script>

<div class="bg-neutral-1000 min-h-screen flex flex-col text-gray-50">
	<div class="sticky absolute">
		<Header />
	</div>

	<main class="w-full flex justify-center h-full flex-grow px-4 overflow-x-hidden">
		<div class="max-w-5xl w-full">
			<slot />
		</div>
	</main>

	<Footer />
</div>

<style>
</style>
