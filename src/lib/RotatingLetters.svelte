<script lang="ts">
	let num = 9;

	const letters = ['K', 'E', 'L'];

	const getLetter = (index) => {
		return letters[index % 3];
	};
</script>

<div class="w-full flex justify-center">
	<div class="endlessRotation h-16 w-16 origin-center">
		{#each Array(num) as _, i}
			<div
				class="absolute h-8 text-l font-black  origin-bottom-left left-[50%]"
				style="transform: rotateZ({(360 / num) * i}deg);"
			>
				{getLetter(i)}
			</div>
		{/each}
	</div>
</div>

<style>
	.endlessRotation {
		animation: rotation 20s infinite linear;
	}
	@keyframes rotation {
		from {
			transform: rotate(0deg);
		}
		to {
			transform: rotate(359deg);
		}
	}
</style>
