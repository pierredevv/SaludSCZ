<script lang="ts">
	import { ALERT_COLORS } from '$lib/types';

	let { nivel = 'verde' } = $props();

	const labels: Record<string, string> = {
		verde: 'Verde',
		amarillo: 'Amarillo',
		naranja: 'Naranja',
		rojo: 'Rojo'
	};
</script>

<span class="badge" style="background: {ALERT_COLORS[nivel] ?? '#64748b'}; color: {nivel === 'rojo' ? '#fff' : '#000'};">
	{labels[nivel] ?? nivel}
</span>
