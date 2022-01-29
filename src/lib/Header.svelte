<script lang="ts">
	import { page } from '$app/stores';
	import RotatingLetters from './RotatingLetters.svelte';
</script>

<header class="flex p-4 justify-between items-center">
	<div>
		<a sveltekit:prefetch href="/"> <RotatingLetters /></a>
	</div>
	<nav class=" ">
		<ul class="flex gap-4 text-lg">
			<li class={$page.url.pathname === '/design' ? 'text-red-600' : ''}>
				<a sveltekit:prefetch href="/design">Design</a>
			</li>
			<li class:active={$page.url.pathname === '/code'}>
				<a sveltekit:prefetch href="/code">Code</a>
			</li>
		</ul>
	</nav>
</header>

<style>
</style>
