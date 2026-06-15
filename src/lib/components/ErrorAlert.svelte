<script lang="ts">
	let { message = '' } = $props();
</script>

{#if message}
	<div class="error-alert">{message}</div>
{/if}

<style>
	.error-alert {
		background: rgba(239, 68, 68, 0.1);
		border: 1px solid var(--color-rojo);
		border-radius: var(--radius);
		padding: 1rem;
		color: var(--color-rojo);
		margin-bottom: 1rem;
	}
</style>
