<script>
	import { stringify } from 'postcss';
	import { marked } from 'marked';

	import index from '../../data/design';
	import rawMarkdown from '../../data/design/design.md?raw';

	const parsedText = marked.parse(rawMarkdown, { breaks: true });

	const basePath = 'src/data/design/';

	const resolveFile = (file) => {
		return basePath + file;
	};
</script>

<svelte:head><title>ZE KEL | DESIGN</title></svelte:head>

<div>
	<div class="head">
		{@html parsedText}
	</div>

	<div class="my-8">
		{#each index.items as item}
			<div class="my-12 first:my-0">
				<h2 class="text-4xl mb-3 font-medium">{item.title}</h2>
				<img src={resolveFile(item.image)} alt={item.title + ' cover'} />
			</div>
		{/each}
	</div>
</div>

<style lang="postcss">
</style>
