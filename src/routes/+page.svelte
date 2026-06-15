<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import type { ResumenZona, AlertaActiva } from '$lib/types';

	let totalCasos = $state(0);
	let alertasActivas = $state(0);
	let zonasAfectadas = $state(0);
	let loading = $state(true);

	onMount(async () => {
		const [casosRes, alertasRes, zonasRes] = await Promise.all([
			supabase.from('caso').select('id_caso', { count: 'exact', head: true }),
			supabase.from('alerta').select('id_alerta', { count: 'exact', head: true }).eq('activa', true),
			supabase.from('v_resumen_zonas').select('id_zona')
		]);

		totalCasos = casosRes.count ?? 0;
		alertasActivas = alertasRes.count ?? 0;
		const uniqueZones = new Set((zonasRes.data ?? []).map((r: any) => r.id_zona));
		zonasAfectadas = uniqueZones.size;
		loading = false;
	});
</script>

<svelte:head>
	<title>SaludSCZ - Inicio</title>
</svelte:head>

<div class="hero">
	<div class="hero-content">
		<h1>Salud<span class="highlight">SCZ</span></h1>
		<p class="subtitle">Sistema de Vigilancia Epidemiologica Tropical</p>
		<p class="description">
			Monitoreo en tiempo real de enfermedades tropicales en Santa Cruz de la Sierra, Bolivia.
			Datos del SEDES SCZ - Boletines Epidemiologicos 2024-2025.
		</p>
		<div class="hero-actions">
			<a href="/mapa" class="btn btn-primary">Ver Mapa de Riesgo</a>
			<a href="/dashboard" class="btn btn-outline">Dashboard</a>
		</div>
	</div>
</div>

{#if !loading}
	<div class="grid-3 stats-grid">
		<div class="card kpi-card">
			<div class="kpi-value">{totalCasos}</div>
			<div class="kpi-label">Casos Totales Registrados</div>
		</div>
		<div class="card kpi-card">
			<div class="kpi-value" style="color: var(--color-naranja)">{alertasActivas}</div>
			<div class="kpi-label">Alertas Activas</div>
		</div>
		<div class="card kpi-card">
			<div class="kpi-value" style="color: var(--color-verde)">{zonasAfectadas}</div>
			<div class="kpi-label">Zonas con Casos</div>
		</div>
	</div>
{/if}

<div class="grid-2 features-grid">
	<div class="card feature-card">
		<div class="feature-icon">&#128205;</div>
		<h3>Mapa Interactivo</h3>
		<p>Visualiza los focos de contagio por zona y barrio de Santa Cruz en un mapa interactivo con capas de calor.</p>
		<a href="/mapa" class="btn btn-outline">Ver Mapa</a>
	</div>
	<div class="card feature-card">
		<div class="feature-icon">&#128202;</div>
		<h3>Dashboard Epidemiologico</h3>
		<p>Graficas de tendencia semanal, distribucion por enfermedad y tasas de incidencia por 100,000 habitantes.</p>
		<a href="/dashboard" class="btn btn-outline">Ver Dashboard</a>
	</div>
	<div class="card feature-card">
		<div class="feature-icon">&#128221;</div>
		<h3>Registro de Casos</h3>
		<p>Formulario para personal medico que permite registrar nuevos casos con seleccion de sintomas.</p>
		<a href="/casos/nuevo" class="btn btn-outline">Registrar Caso</a>
	</div>
	<div class="card feature-card">
		<div class="feature-icon">&#9888;&#65039;</div>
		<h3>Alertas Automaticas</h3>
		<p>Sistema de alertas por nivel de severidad cuando una zona supera el umbral de incidencia.</p>
		<a href="/alertas" class="btn btn-outline">Ver Alertas</a>
	</div>
</div>

<div class="card tech-section">
	<h3>Tecnologias del Proyecto</h3>
	<div class="tech-grid">
		<div class="tech-item">
			<strong>Base de Datos</strong>
			<span>PostgreSQL via Supabase</span>
		</div>
		<div class="tech-item">
			<strong>Backend</strong>
			<span>Supabase REST API + Edge Functions</span>
		</div>
		<div class="tech-item">
			<strong>Frontend</strong>
			<span>SvelteKit + TypeScript</span>
		</div>
		<div class="tech-item">
			<strong>Mapas</strong>
			<span>Leaflet.js + GeoJSON SCZ</span>
		</div>
		<div class="tech-item">
			<strong>Graficas</strong>
			<span>Chart.js</span>
		</div>
		<div class="tech-item">
			<strong>Datos</strong>
			<span>SEDES SCZ + INE + OPS/OMS</span>
		</div>
	</div>
</div>

<style>
	.hero {
		text-align: center;
		padding: 3rem 0 2rem;
	}

	.hero h1 {
		font-size: 3rem;
		font-weight: 700;
		margin-bottom: 0.5rem;
	}

	.highlight {
		color: var(--color-primary);
	}

	.subtitle {
		font-size: 1.25rem;
		color: var(--color-text-muted);
		margin-bottom: 0.5rem;
	}

	.description {
		max-width: 600px;
		margin: 0 auto 1.5rem;
		color: var(--color-text-muted);
	}

	.hero-actions {
		display: flex;
		gap: 1rem;
		justify-content: center;
	}

	.stats-grid {
		margin-bottom: 2rem;
	}

	.features-grid {
		margin-bottom: 2rem;
	}

	.feature-card {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.feature-icon {
		font-size: 2rem;
	}

	.feature-card h3 {
		font-size: 1.1rem;
	}

	.feature-card p {
		color: var(--color-text-muted);
		font-size: 0.9rem;
		flex: 1;
	}

	.tech-section h3 {
		margin-bottom: 1rem;
	}

	.tech-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1rem;
	}

	.tech-item {
		display: flex;
		flex-direction: column;
		padding: 0.75rem;
		background: var(--color-surface-2);
		border-radius: var(--radius);
	}

	.tech-item strong {
		font-size: 0.85rem;
		color: var(--color-primary);
	}

	.tech-item span {
		font-size: 0.8rem;
		color: var(--color-text-muted);
	}

	@media (max-width: 768px) {
		.hero h1 {
			font-size: 2rem;
		}

		.tech-grid {
			grid-template-columns: repeat(2, 1fr);
		}
	}
</style>
