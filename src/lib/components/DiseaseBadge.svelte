<script lang="ts">
	import { DISEASE_COLORS } from '$lib/types';

	let { nombre = '' } = $props();
</script>

<span class="badge" style="background: {DISEASE_COLORS[nombre] ?? '#64748b'}; color: #fff;">
	{nombre}
</span>
