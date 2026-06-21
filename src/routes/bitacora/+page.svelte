<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import type { BitacoraAuditoria } from '$lib/types';

	let registros = $state<BitacoraAuditoria[]>([]);
	let loading = $state(true);
	let expandedId = $state<number | null>(null);

	onMount(async () => {
		const { data } = await supabase.from('v_bitacora_reciente').select('*');
		registros = (data ?? []) as unknown as BitacoraAuditoria[];
		loading = false;
	});

	function formatDate(d: string): string {
		return new Date(d).toLocaleString('es-BO', { dateStyle: 'medium', timeStyle: 'short' });
	}

	function opColor(op: string): string {
		if (op === 'INSERT') return '#22c55e';
		if (op === 'UPDATE') return '#eab308';
		if (op === 'DELETE') return '#ef4444';
		return '#64748b';
	}
</script>

<svelte:head>
	<title>Bitácora - SaludSCZ</title>
</svelte:head>

<h1>Bitácora de Auditoría</h1>
<p style="color: var(--color-text-muted); margin-bottom: 1.5rem;">
	Registro automático de todas las modificaciones a datos clínicos del sistema.
</p>

{#if loading}
	<div class="loading">Cargando bitácora...</div>
{:else if registros.length === 0}
	<div class="card" style="text-align: center; padding: 3rem;">
		<p style="color: var(--color-text-muted);">No hay registros de auditoría aún. Se generarán automáticamente al insertar, actualizar o eliminar casos.</p>
	</div>
{:else}
	<div class="card">
		<div class="table-wrapper">
			<table>
				<thead>
					<tr>
						<th>Fecha</th>
						<th>Tabla</th>
						<th>Operación</th>
						<th>ID Registro</th>
						<th>Usuario</th>
						<th>Detalles</th>
					</tr>
				</thead>
				<tbody>
					{#each registros as r}
						<tr>
							<td>{formatDate(r.fecha)}</td>
							<td><strong>{r.tabla_afectada}</strong></td>
							<td>
								<span class="badge" style="background: {opColor(r.operacion)}; color: {r.operacion === 'UPDATE' ? '#000' : '#fff'};">
									{r.operacion}
								</span>
							</td>
							<td>#{r.id_registro}</td>
							<td style="color: var(--color-primary);">{r.usuario_email ?? 'Sistema'}</td>
							<td>
								<button class="btn btn-outline" style="padding: 0.2rem 0.5rem; font-size: 0.75rem;"
									onclick={() => expandedId = expandedId === r.id_bitacora ? null : r.id_bitacora}>
									{expandedId === r.id_bitacora ? 'Ocultar' : 'Ver JSON'}
								</button>
							</td>
						</tr>
						{#if expandedId === r.id_bitacora}
							<tr>
								<td colspan="6" style="padding: 1rem;">
									<div class="json-view">
										{#if r.datos_anteriores}
											<div>
												<strong style="color: var(--color-rojo);">Datos Anteriores:</strong>
												<pre>{JSON.stringify(r.datos_anteriores, null, 2)}</pre>
											</div>
										{/if}
										{#if r.datos_nuevos}
											<div>
												<strong style="color: var(--color-verde);">Datos Nuevos:</strong>
												<pre>{JSON.stringify(r.datos_nuevos, null, 2)}</pre>
											</div>
										{/if}
									</div>
								</td>
							</tr>
						{/if}
					{/each}
				</tbody>
			</table>
		</div>
	</div>
{/if}

<style>
	.table-wrapper { overflow-x: auto; }
	.json-view {
		display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;
		background: var(--color-surface-2); border-radius: var(--radius); padding: 1rem;
	}
	.json-view pre {
		font-size: 0.75rem; color: var(--color-text-muted); white-space: pre-wrap;
		word-break: break-all; margin-top: 0.3rem;
		background: var(--color-bg); padding: 0.5rem; border-radius: var(--radius);
	}
	@media (max-width: 768px) {
		.json-view { grid-template-columns: 1fr; }
	}
</style>
