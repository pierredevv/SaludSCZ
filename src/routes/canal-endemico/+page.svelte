<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import type { CanalEndemico } from '$lib/types';
	import { CANAL_COLORS, CANAL_LABELS, DISEASE_COLORS } from '$lib/types';
	import Chart from 'chart.js/auto';

	let canalData = $state<CanalEndemico[]>([]);
	let loading = $state(true);
	let selectedEnfermedad = $state('Dengue');
	let enfermedades = $state<string[]>([]);
	let chartCanvas = $state<HTMLCanvasElement | null>(null);
	let chartInstance: Chart | null = null;
	let currentWeek = $state(0);
	let currentStatus = $state<CanalEndemico | null>(null);

	onMount(async () => {
		const { data: res } = await supabase.from('v_canal_endemico').select('*');
		canalData = (res ?? []) as unknown as CanalEndemico[];
		enfermedades = [...new Set(canalData.map(d => d.enfermedad))];
		if (enfermedades.length > 0 && !enfermedades.includes(selectedEnfermedad)) {
			selectedEnfermedad = enfermedades[0];
		}
		currentWeek = getCurrentEpiWeek();
		loading = false;
		await new Promise(r => setTimeout(r, 100));
		renderChart();
	});

	function getCurrentEpiWeek(): number {
		const now = new Date();
		const start = new Date(now.getFullYear(), 0, 1);
		const diff = now.getTime() - start.getTime();
		return Math.ceil((diff / 86400000 + start.getDay() + 1) / 7);
	}

	function getFilteredData(): CanalEndemico[] {
		return canalData.filter(d => d.enfermedad === selectedEnfermedad).sort((a, b) => a.semana_epi - b.semana_epi);
	}

	function renderChart() {
		if (!chartCanvas) return;
		if (chartInstance) chartInstance.destroy();

		const filtered = getFilteredData();
		if (filtered.length === 0) return;

		const labels = filtered.map(d => `SE ${d.semana_epi}`);
		const curr = filtered.find(d => d.semana_epi === currentWeek);
		currentStatus = curr ?? null;

		chartInstance = new Chart(chartCanvas, {
			type: 'line',
			data: {
				labels,
				datasets: [
					{
						label: 'Zona de Éxito (P25)',
						data: filtered.map(d => d.zona_exito),
						borderColor: CANAL_COLORS.exito,
						backgroundColor: CANAL_COLORS.exito + '20',
						fill: true, tension: 0.3, pointRadius: 0, borderWidth: 1.5
					},
					{
						label: 'Zona de Seguridad (P50)',
						data: filtered.map(d => d.zona_seguridad),
						borderColor: CANAL_COLORS.seguridad,
						backgroundColor: CANAL_COLORS.seguridad + '20',
						fill: '-1', tension: 0.3, pointRadius: 0, borderWidth: 1.5
					},
					{
						label: 'Zona de Alerta (P75)',
						data: filtered.map(d => d.zona_alerta),
						borderColor: CANAL_COLORS.alerta,
						backgroundColor: CANAL_COLORS.alerta + '20',
						fill: '-1', tension: 0.3, pointRadius: 0, borderWidth: 1.5
					},
					{
						label: 'Casos Actuales',
						data: filtered.map(d => d.casos_actuales),
						borderColor: '#f1f5f9',
						backgroundColor: 'transparent',
						borderWidth: 2.5, tension: 0.3, pointRadius: 4,
						pointBackgroundColor: filtered.map(d => CANAL_COLORS[d.clasificacion_canal] ?? '#fff')
					}
				]
			},
			options: {
				responsive: true,
				plugins: {
					legend: { position: 'bottom', labels: { color: '#94a3b8', padding: 15 } },
					tooltip: {
						callbacks: {
							afterBody: (items) => {
								const idx = items[0]?.dataIndex;
								if (idx !== undefined) {
									const d = filtered[idx];
									return `Clasificación: ${CANAL_LABELS[d.clasificacion_canal]}`;
								}
								return '';
							}
						}
					}
				},
				scales: {
					x: { ticks: { color: '#94a3b8', maxTicksLimit: 20 }, grid: { color: '#334155' } },
					y: { ticks: { color: '#94a3b8' }, grid: { color: '#334155' }, beginAtZero: true }
				}
			}
		});
	}

	function changeEnfermedad() {
		renderChart();
	}
</script>

<svelte:head>
	<title>Canal Endémico - SaludSCZ</title>
</svelte:head>

<h1>Canal Endémico</h1>
<p style="color: var(--color-text-muted); margin-bottom: 1.5rem;">
	Herramienta epidemiológica para clasificar la situación actual vs. percentiles históricos por semana epidemiológica.
</p>

{#if loading}
	<div class="loading">Cargando datos del canal endémico...</div>
{:else}
	<div class="controls" style="margin-bottom: 1.5rem; display: flex; gap: 1rem; flex-wrap: wrap; align-items: center;">
		<label for="select-enfermedad" style="color: var(--color-text-muted); font-size: 0.9rem;">Enfermedad:</label>
		<select id="select-enfermedad" bind:value={selectedEnfermedad} onchange={changeEnfermedad} style="width: auto;">
			{#each enfermedades as enf}
				<option value={enf}>{enf}</option>
			{/each}
		</select>
		<span style="color: var(--color-text-muted); font-size: 0.85rem;">
			Semana epidemiológica actual: <strong style="color: var(--color-primary);">SE {currentWeek}</strong>
		</span>
	</div>

	{#if currentStatus}
		<div class="grid-4" style="margin-bottom: 1.5rem;">
			<div class="card kpi-card">
				<div class="kpi-value" style="color: {CANAL_COLORS[currentStatus.clasificacion_canal]};">
					{currentStatus.casos_actuales}
				</div>
				<div class="kpi-label">Casos esta semana</div>
			</div>
			<div class="card kpi-card">
				<div class="kpi-value" style="color: {CANAL_COLORS.exito};">{currentStatus.zona_exito}</div>
				<div class="kpi-label">Umbral Éxito (P25)</div>
			</div>
			<div class="card kpi-card">
				<div class="kpi-value" style="color: {CANAL_COLORS.alerta};">{currentStatus.zona_alerta}</div>
				<div class="kpi-label">Umbral Alerta (P75)</div>
			</div>
			<div class="card kpi-card">
				<div class="kpi-value" style="font-size: 1.2rem; color: {CANAL_COLORS[currentStatus.clasificacion_canal]};">
					{CANAL_LABELS[currentStatus.clasificacion_canal]}
				</div>
				<div class="kpi-label">Clasificación Actual</div>
			</div>
		</div>
	{/if}

	<div class="card" style="margin-bottom: 2rem;">
		<div class="card-header">Canal Endémico — {selectedEnfermedad}</div>
		<p style="color: var(--color-text-muted); font-size: 0.8rem; margin-bottom: 1rem;">
			Las bandas representan: <span style="color: {CANAL_COLORS.exito};">■ Éxito (&lt;P25)</span> |
			<span style="color: {CANAL_COLORS.seguridad};">■ Seguridad (P25-P50)</span> |
			<span style="color: {CANAL_COLORS.alerta};">■ Alerta (P50-P75)</span> |
			<span style="color: {CANAL_COLORS.epidemia};">■ Epidemia (&gt;P75)</span>
		</p>
		<div style="height: 400px; position: relative;">
			<canvas bind:this={chartCanvas}></canvas>
		</div>
	</div>

	<div class="card">
		<div class="card-header">Datos Semanales — {selectedEnfermedad}</div>
		<div class="table-wrapper">
			<table>
				<thead>
					<tr>
						<th>SE</th>
						<th>P25</th>
						<th>P50</th>
						<th>P75</th>
						<th>Actual</th>
						<th>Clasificación</th>
					</tr>
				</thead>
				<tbody>
					{#each getFilteredData() as d}
						<tr style="{d.semana_epi === currentWeek ? 'background: var(--color-surface-2);' : ''}">
							<td><strong>SE {d.semana_epi}</strong></td>
							<td>{d.zona_exito}</td>
							<td>{d.zona_seguridad}</td>
							<td>{d.zona_alerta}</td>
							<td><strong>{d.casos_actuales}</strong></td>
							<td>
								<span class="badge" style="background: {CANAL_COLORS[d.clasificacion_canal]}; color: {d.clasificacion_canal === 'alerta' || d.clasificacion_canal === 'exito' ? '#000' : '#fff'};">
									{CANAL_LABELS[d.clasificacion_canal]}
								</span>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>
{/if}

<style>
	.table-wrapper { overflow-x: auto; }
</style>
