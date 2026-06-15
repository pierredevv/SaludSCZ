<script lang="ts">
	let { value = 0, label = '', color = '' } = $props();
</script>

<div class="card kpi-card">
	<div class="kpi-value" style={color ? `color: ${color}` : ''}>{value}</div>
	<div class="kpi-label">{label}</div>
</div>
