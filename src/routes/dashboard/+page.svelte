<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import type { ResumenZona, EvolucionSemanal, TasaIncidencia } from '$lib/types';
	import { DISEASE_COLORS, ALERT_COLORS } from '$lib/types';
	import Chart from 'chart.js/auto';

	let resumenZonas = $state<ResumenZona[]>([]);
	let evolucion = $state<EvolucionSemanal[]>([]);
	let tasas = $state<TasaIncidencia[]>([]);
	let totalCasos = $state(0);
	let confirmados = $state(0);
	let alertasActivas = $state(0);
	let loading = $state(true);
	let error = $state('');

	let casosChart = $state<HTMLCanvasElement | null>(null);
	let tendenciaChart = $state<HTMLCanvasElement | null>(null);
	let enfermedadChart = $state<HTMLCanvasElement | null>(null);
	let tasaChart = $state<HTMLCanvasElement | null>(null);

	onMount(async () => {
		const [resumenRes, evolRes, tasaRes, totalRes, alertasRes] = await Promise.all([
			supabase.from('v_resumen_zonas').select('*'),
			supabase.from('v_evolucion_semanal').select('*').order('anio', { ascending: false }).order('semana', { ascending: false }).limit(20),
			supabase.from('v_tasa_incidencia').select('*'),
			supabase.from('caso').select('id_caso', { count: 'exact', head: true }),
			supabase.from('alerta').select('id_alerta', { count: 'exact', head: true }).eq('activa', true)
		]);

		if (resumenRes.error) error = resumenRes.error.message;
		else resumenZonas = resumenRes.data ?? [];

		if (evolRes.error) error = evolRes.error.message;
		else evolucion = evolRes.data ?? [];

		tasas = (tasaRes.data ?? []) as unknown as TasaIncidencia[];
		totalCasos = totalRes.count ?? 0;
		alertasActivas = alertasRes.count ?? 0;

		confirmados = resumenZonas.reduce((sum, r) => sum + (r.confirmados ?? 0), 0);

		loading = false;

		await tick();
		renderCharts();
	});

	async function tick() {
		return new Promise((r) => setTimeout(r, 100));
	}

	function renderCharts() {
		if (casosChart && resumenZonas.length > 0) {
			const zonas = [...new Set(resumenZonas.map((r) => r.zona))];
			const data = zonas.map((z) => {
				return resumenZonas.filter((r) => r.zona === z).reduce((sum, r) => sum + r.total_casos, 0);
			});

			new Chart(casosChart, {
				type: 'bar',
				data: {
					labels: zonas,
					datasets: [{
						label: 'Casos por zona',
						data,
						backgroundColor: 'rgba(56, 189, 248, 0.6)',
						borderColor: 'rgba(56, 189, 248, 1)',
						borderWidth: 1
					}]
				},
				options: {
					indexAxis: 'y',
					responsive: true,
					plugins: { legend: { display: false } },
					scales: {
						x: { ticks: { color: '#94a3b8' }, grid: { color: '#334155' } },
						y: { ticks: { color: '#94a3b8' }, grid: { color: '#334155' } }
					}
				}
			});
		}

		if (enfermedadChart && resumenZonas.length > 0) {
			const enfermedades = [...new Set(resumenZonas.map((r) => r.enfermedad))];
			const data = enfermedades.map((e) => {
				return resumenZonas.filter((r) => r.enfermedad === e).reduce((sum, r) => sum + r.total_casos, 0);
			});

			new Chart(enfermedadChart, {
				type: 'doughnut',
				data: {
					labels: enfermedades,
					datasets: [{
						data,
						backgroundColor: enfermedades.map((e) => DISEASE_COLORS[e] || '#64748b'),
						borderWidth: 0
					}]
				},
				options: {
					responsive: true,
					plugins: {
						legend: {
							position: 'bottom',
							labels: { color: '#94a3b8', padding: 15 }
						}
					}
				}
			});
		}

		if (tendenciaChart && evolucion.length > 0) {
			const semanas = [...new Set(evolucion.map((e) => `S${e.semana}`))].reverse().slice(0, 12);
			const enfermedades = [...new Set(evolucion.map((e) => e.enfermedad))];
			const datasets = enfermedades.map((enf) => ({
				label: enf,
				data: semanas.map((s) => {
					const semanaNum = parseInt(s.replace('S', ''));
					const entry = evolucion.find((e) => e.semana === semanaNum && e.enfermedad === enf);
					return entry?.total_casos ?? 0;
				}),
				borderColor: DISEASE_COLORS[enf] || '#64748b',
				backgroundColor: 'transparent',
				tension: 0.3,
				pointRadius: 3
			}));

			new Chart(tendenciaChart, {
				type: 'line',
				data: { labels: semanas, datasets },
				options: {
					responsive: true,
					plugins: {
						legend: {
							position: 'bottom',
							labels: { color: '#94a3b8', padding: 15 }
						}
					},
					scales: {
						x: { ticks: { color: '#94a3b8' }, grid: { color: '#334155' } },
						y: { ticks: { color: '#94a3b8' }, grid: { color: '#334155' } }
					}
				}
			});
		}

		if (tasaChart && tasas.length > 0) {
			const clasificacionColors: Record<string, string> = {
				muy_alta: 'rgba(239, 68, 68, 0.7)',
				alta: 'rgba(249, 115, 22, 0.7)',
				moderada: 'rgba(234, 179, 8, 0.7)',
				baja: 'rgba(34, 197, 94, 0.7)'
			};

			const sorted = [...tasas].sort((a, b) => (b.tasa_por_100k ?? 0) - (a.tasa_por_100k ?? 0));

			new Chart(tasaChart, {
				type: 'bar',
				data: {
					labels: sorted.map((t) => t.zona),
					datasets: [{
						label: 'Tasa por 100k hab.',
						data: sorted.map((t) => t.tasa_por_100k ?? 0),
						backgroundColor: sorted.map((t) => clasificacionColors[t.clasificacion] ?? 'rgba(100, 116, 139, 0.5)'),
						borderWidth: 0
					}]
				},
				options: {
					indexAxis: 'y',
					responsive: true,
					plugins: { legend: { display: false } },
					scales: {
						x: { ticks: { color: '#94a3b8' }, grid: { color: '#334155' } },
						y: { ticks: { color: '#94a3b8', font: { size: 11 } }, grid: { color: '#334155' } }
					}
				}
			});
		}
	}
</script>

<svelte:head>
	<title>Dashboard - SaludSCZ</title>
</svelte:head>

<h1>Dashboard Epidemiologico</h1>
<p style="color: var(--color-text-muted); margin-bottom: 2rem;">
	Resumen de enfermedades tropicales en Santa Cruz de la Sierra
</p>

{#if loading}
	<div class="loading">Cargando datos...</div>
{:else if error}
	<div class="error">{error}</div>
{:else}
	<div class="grid-4" style="margin-bottom: 2rem;">
		<div class="card kpi-card">
			<div class="kpi-value">{totalCasos}</div>
			<div class="kpi-label">Casos Totales</div>
		</div>
		<div class="card kpi-card">
			<div class="kpi-value" style="color: var(--color-rojo)">{confirmados}</div>
			<div class="kpi-label">Confirmados</div>
		</div>
		<div class="card kpi-card">
			<div class="kpi-value" style="color: var(--color-amarillo)">{totalCasos - confirmados}</div>
			<div class="kpi-label">Sospechosos</div>
		</div>
		<div class="card kpi-card">
			<div class="kpi-value" style="color: var(--color-naranja)">{alertasActivas}</div>
			<div class="kpi-label">Alertas Activas</div>
		</div>
	</div>

	<div class="grid-2" style="margin-bottom: 2rem;">
		<div class="card">
			<div class="card-header">Casos por Zona</div>
			<div class="chart-container">
				<canvas bind:this={casosChart}></canvas>
			</div>
		</div>
		<div class="card">
			<div class="card-header">Distribucion por Enfermedad</div>
			<div class="chart-container">
				<canvas bind:this={enfermedadChart}></canvas>
			</div>
		</div>
	</div>

	<div class="card" style="margin-bottom: 2rem;">
		<div class="card-header">Tasa de Incidencia por 100.000 Habitantes</div>
		<p style="color: var(--color-text-muted); font-size: 0.85rem; margin-bottom: 1rem;">
			IndicadorOPS: muy_alta (&#8805;300), alta (&#8805;100), moderada (&#8805;30), baja (&lt;30)
		</p>
		<div class="chart-container">
			<canvas bind:this={tasaChart}></canvas>
		</div>
	</div>

	<div class="card" style="margin-bottom: 2rem;">
		<div class="card-header">Evolucion Semanal</div>
		<div class="chart-container-wide">
			<canvas bind:this={tendenciaChart}></canvas>
		</div>
	</div>

	<div class="card" style="margin-bottom: 2rem;">
		<div class="card-header">Tabla de Tasa de Incidencia</div>
		<div class="table-wrapper">
			<table>
				<thead>
					<tr>
						<th>Zona</th>
						<th>Poblacion</th>
						<th>Casos</th>
						<th>Tasa / 100k</th>
						<th>Clasificacion</th>
					</tr>
				</thead>
				<tbody>
					{#each tasas as t}
						<tr>
							<td><strong>{t.zona}</strong></td>
							<td>{(t.poblacion ?? 0).toLocaleString()}</td>
							<td>{t.total_casos}</td>
							<td><strong>{t.tasa_por_100k ?? 0}</strong></td>
							<td>
								<span class="badge" style="background: {ALERT_COLORS[t.clasificacion === 'muy_alta' ? 'rojo' : t.clasificacion === 'alta' ? 'naranja' : t.clasificacion === 'moderada' ? 'amarillo' : 'verde']}; color: {t.clasificacion === 'muy_alta' || t.clasificacion === 'alta' ? '#fff' : '#000'};">
									{t.clasificacion}
								</span>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>

	<div class="card">
		<div class="card-header">Resumen por Zona</div>
		<div class="table-wrapper">
			<table>
				<thead>
					<tr>
						<th>Zona</th>
						<th>Distrito</th>
						<th>Enfermedad</th>
						<th>Total Casos</th>
						<th>Confirmados</th>
						<th>Sospechosos</th>
						<th>Ultimo Caso</th>
					</tr>
				</thead>
				<tbody>
					{#each resumenZonas as r}
						<tr>
							<td><strong>{r.zona}</strong></td>
							<td>{r.distrito ?? '-'}</td>
							<td>
								<span class="badge" style="background: {DISEASE_COLORS[r.enfermedad] ?? '#64748b'}; color: #fff;">
									{r.enfermedad}
								</span>
							</td>
							<td>{r.total_casos}</td>
							<td style="color: var(--color-verde)">{r.confirmados}</td>
							<td style="color: var(--color-amarillo)">{r.sospechosos}</td>
							<td>{r.ultimo_caso ?? '-'}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>
{/if}

<style>
	.chart-container {
		height: 350px;
		position: relative;
	}

	.chart-container-wide {
		height: 300px;
		position: relative;
	}

	.table-wrapper {
		overflow-x: auto;
	}
</style>
