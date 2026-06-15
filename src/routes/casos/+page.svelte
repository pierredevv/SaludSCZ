<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabase';
	import { canRegisterCase, isAuthenticated } from '$lib/stores/auth';
	import type { CasoConRelaciones } from '$lib/types';
	import { DISEASE_COLORS } from '$lib/types';

	let casos = $state<CasoConRelaciones[]>([]);
	let loading = $state(true);
	let filtroEnfermedad = $state('');
	let filtroEstado = $state('');

	onMount(async () => {
		await loadCasos();
	});

	async function loadCasos() {
		loading = true;
		let query = supabase
			.from('caso')
			.select('*, paciente(*), enfermedad(*), centro_salud(*), usuario(*)')
			.order('fecha_registro', { ascending: false })
			.limit(100);

		if (filtroEnfermedad) {
			query = query.eq('id_enfermedad', parseInt(filtroEnfermedad));
		}
		if (filtroEstado) {
			query = query.eq('estado', filtroEstado);
		}

		const { data, error } = await query;
		if (!error) casos = (data ?? []) as unknown as CasoConRelaciones[];
		loading = false;
	}

	function estadoBadge(estado: string): string {
		const colors: Record<string, string> = {
			sospechoso: 'var(--color-amarillo)',
			confirmado: 'var(--color-rojo)',
			descartado: 'var(--color-text-muted)',
			recuperado: 'var(--color-verde)',
			fallecido: '#6b7280'
		};
		return colors[estado] ?? '#64748b';
	}

	$effect(() => {
		filtroEnfermedad;
		filtroEstado;
		loadCasos();
	});
</script>

<svelte:head>
	<title>Casos - SaludSCZ</title>
</svelte:head>

<div class="page-header">
	<div>
		<h1>Registro de Casos</h1>
		<p style="color: var(--color-text-muted);">Historial de casos registrados en el sistema</p>
	</div>
	{#if $canRegisterCase}
		<a href="/casos/nuevo" class="btn btn-primary">+ Nuevo Caso</a>
	{/if}
</div>

<div class="filters card" style="margin-bottom: 1.5rem;">
	<div class="filter-row">
		<div class="form-group" style="margin-bottom: 0;">
			<label for="enf">Enfermedad</label>
			<select id="enf" bind:value={filtroEnfermedad}>
				<option value="">Todas</option>
				<option value="1">Dengue</option>
				<option value="2">Chikungunya</option>
				<option value="3">Zika</option>
				<option value="4">Leishmaniasis</option>
				<option value="5">Malaria</option>
			</select>
		</div>
		<div class="form-group" style="margin-bottom: 0;">
			<label for="est">Estado</label>
			<select id="est" bind:value={filtroEstado}>
				<option value="">Todos</option>
				<option value="sospechoso">Sospechoso</option>
				<option value="confirmado">Confirmado</option>
				<option value="descartado">Descartado</option>
				<option value="recuperado">Recuperado</option>
			</select>
		</div>
	</div>
</div>

{#if loading}
	<div class="loading">Cargando casos...</div>
{:else}
	<div class="card">
		<div class="table-wrapper">
			<table>
				<thead>
					<tr>
						<th>ID</th>
						<th>Fecha</th>
						<th>Paciente</th>
						<th>Enfermedad</th>
						<th>Estado</th>
						<th>Centro Salud</th>
						<th>Usuario</th>
					</tr>
				</thead>
				<tbody>
					{#each casos as c}
						<tr>
							<td>#{c.id_caso}</td>
							<td>{c.fecha_registro}</td>
							<td>{c.paciente?.nombre} {c.paciente?.apellido}</td>
							<td>
								<span class="badge" style="background: {DISEASE_COLORS[c.enfermedad?.nombre] ?? '#64748b'}; color: #fff;">
									{c.enfermedad?.nombre ?? '-'}
								</span>
							</td>
							<td>
								<span class="badge" style="background: {estadoBadge(c.estado)}; color: #fff;">
									{c.estado}
								</span>
							</td>
							<td>{c.centro_salud?.nombre ?? '-'}</td>
							<td>{c.usuario?.nombre ?? '-'}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>
{/if}

<style>
	.page-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1.5rem;
	}

	.filter-row {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 1rem;
	}

	.table-wrapper {
		overflow-x: auto;
	}

	@media (max-width: 768px) {
		.page-header {
			flex-direction: column;
			gap: 1rem;
			align-items: stretch;
		}

		.filter-row {
			grid-template-columns: 1fr;
		}
	}
</style>
