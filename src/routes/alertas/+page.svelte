<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import type { AlertaActiva } from '$lib/types';
	import { ALERT_COLORS, ALERT_LABELS } from '$lib/types';

	let alertas = $state<AlertaActiva[]>([]);
	let loading = $state(true);
	let filtroNivel = $state('');

	onMount(async () => {
		await loadAlertas();
	});

	async function loadAlertas() {
		loading = true;
		let query = supabase
			.from('v_alertas_activas')
			.select('*');

		if (filtroNivel) {
			query = query.eq('nivel', filtroNivel);
		}

		const { data, error } = await query;
		if (!error) alertas = (data ?? []) as unknown as AlertaActiva[];
		loading = false;
	}

	function nivelIcon(nivel: string): string {
		const icons: Record<string, string> = {
			verde: '&#128994;',
			amarillo: '&#128992;',
			naranja: '&#128993;',
			rojo: '&#128308;'
		};
		return icons[nivel] ?? '&#9898;';
	}

	$effect(() => {
		filtroNivel;
		loadAlertas();
	});
</script>

<svelte:head>
	<title>Alertas - SaludSCZ</title>
</svelte:head>

<h1>Alertas Epidemiologicas</h1>
<p style="color: var(--color-text-muted); margin-bottom: 1.5rem;">
	Alertas activas generadas por el sistema de vigilancia
</p>

<div class="filters" style="margin-bottom: 1.5rem; display: flex; gap: 0.5rem; flex-wrap: wrap;">
	<button class="btn btn-outline" class:active={filtroNivel === ''} onclick={() => (filtroNivel = '')}>
		Todas
	</button>
	<button class="btn btn-outline nivel-btn" class:active={filtroNivel === 'rojo'}
		onclick={() => (filtroNivel = 'rojo')} style="border-color: var(--color-rojo);">
		Rojo
	</button>
	<button class="btn btn-outline nivel-btn" class:active={filtroNivel === 'naranja'}
		onclick={() => (filtroNivel = 'naranja')} style="border-color: var(--color-naranja);">
		Naranja
	</button>
	<button class="btn btn-outline nivel-btn" class:active={filtroNivel === 'amarillo'}
		onclick={() => (filtroNivel = 'amarillo')} style="border-color: var(--color-amarillo);">
		Amarillo
	</button>
	<button class="btn btn-outline nivel-btn" class:active={filtroNivel === 'verde'}
		onclick={() => (filtroNivel = 'verde')} style="border-color: var(--color-verde);">
		Verde
	</button>
</div>

{#if loading}
	<div class="loading">Cargando alertas...</div>
{:else if alertas.length === 0}
	<div class="card" style="text-align: center; padding: 3rem;">
		<p style="color: var(--color-text-muted);">No hay alertas {filtroNivel ? `de nivel ${filtroNivel}` : 'activas'} en este momento.</p>
	</div>
{:else}
	<div class="alertas-grid">
		{#each alertas as a}
			<div class="card alerta-card" style="border-left: 4px solid {ALERT_COLORS[a.nivel]};">
				<div class="alerta-header">
					<span class="alerta-icon">{@html nivelIcon(a.nivel)}</span>
					<div>
						<h3 style="margin: 0;">{a.zona}</h3>
						<p class="alerta-distrito">Distrito {a.distrito ?? '-'}</p>
					</div>
					<span class="badge badge-{a.nivel}" style="margin-left: auto;">
						{a.nivel}
					</span>
				</div>

				<div class="alerta-body">
					<p class="alerta-tipo">{a.tipo}</p>
					{#if a.mensaje}
						<p class="alerta-mensaje">{a.mensaje}</p>
					{/if}
					<div class="alerta-meta">
						<span>Inicio: {a.fecha_inicio}</span>
						{#if a.casos_desde_alerta}
							<span>Casos desde alerta: <strong>{a.casos_desde_alerta}</strong></span>
						{/if}
					</div>
				</div>

				<a href="/mapa?lat={a.latitud}&lng={a.longitud}&zonaId={a.id_zona}" class="btn btn-outline btn-sm">Ver en mapa</a>
			</div>
		{/each}
	</div>
{/if}

<style>
	.alertas-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
		gap: 1rem;
	}

	.alerta-card {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.alerta-header {
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.alerta-icon {
		font-size: 1.5rem;
	}

	.alerta-distrito {
		color: var(--color-text-muted);
		font-size: 0.85rem;
		margin: 0;
	}

	.alerta-body {
		flex: 1;
	}

	.alerta-tipo {
		font-size: 0.8rem;
		color: var(--color-primary);
		text-transform: uppercase;
		font-weight: 600;
		margin-bottom: 0.25rem;
	}

	.alerta-mensaje {
		font-size: 0.9rem;
		color: var(--color-text-muted);
		margin-bottom: 0.5rem;
	}

	.alerta-meta {
		display: flex;
		gap: 1rem;
		font-size: 0.8rem;
		color: var(--color-text-muted);
	}

	.btn-sm {
		padding: 0.4rem 0.8rem;
		font-size: 0.8rem;
		align-self: flex-start;
	}

	.nivel-btn {
		transition: all 0.2s;
	}

	.active {
		background: var(--color-surface-2) !important;
		color: var(--color-text) !important;
	}

	@media (max-width: 768px) {
		.alertas-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
