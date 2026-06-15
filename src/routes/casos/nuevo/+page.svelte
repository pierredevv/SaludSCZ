<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabase';
	import { auth, isAuthenticated } from '$lib/stores/auth';
	import type { Zona, Enfermedad, CentroSalud, Sintoma } from '$lib/types';

	let zonas = $state<Zona[]>([]);
	let enfermedades = $state<Enfermedad[]>([]);
	let centros = $state<CentroSalud[]>([]);
	let sintomas = $state<Sintoma[]>([]);

	let loading = $state(true);
	let submitting = $state(false);
	let error = $state('');
	let success = $state(false);

	let form = $state({
		nombre: '',
		apellido: '',
		fecha_nacimiento: '',
		sexo: 'M' as 'M' | 'F' | 'O',
		id_zona: '',
		id_enfermedad: '',
		id_centro: '',
		estado: 'sospechoso' as string,
		confirmacion: 'clinica' as string,
		fecha_inicio_sintomas: '',
		sintomasSeleccionados: [] as number[]
	});

	onMount(async () => {
		const [zonasRes, enfRes, centrosRes, sintRes] = await Promise.all([
			supabase.from('zona').select('*').order('nombre'),
			supabase.from('enfermedad').select('*').order('nombre'),
			supabase.from('centro_salud').select('*').order('nombre'),
			supabase.from('sintoma').select('*').order('nombre')
		]);

		zonas = zonasRes.data ?? [];
		enfermedades = enfRes.data ?? [];
		centros = centrosRes.data ?? [];
		sintomas = sintRes.data ?? [];
		loading = false;
	});

	function toggleSintoma(id: number) {
		const idx = form.sintomasSeleccionados.indexOf(id);
		if (idx === -1) {
			form.sintomasSeleccionados = [...form.sintomasSeleccionados, id];
		} else {
			form.sintomasSeleccionados = form.sintomasSeleccionados.filter((s) => s !== id);
		}
	}

	async function handleSubmit() {
		if (!form.nombre || !form.apellido || !form.id_enfermedad || !form.id_centro) {
			error = 'Por favor complete todos los campos obligatorios.';
			return;
		}

		submitting = true;
		error = '';

		const usuarioId = $auth.usuarioId;

		if (!usuarioId) {
			error = 'No se pudo identificar el usuario. Inicie sesion nuevamente.';
			submitting = false;
			return;
		}

		const { data: paciente, error: pacienteErr } = await supabase
			.from('paciente')
			.insert({
				nombre: form.nombre,
				apellido: form.apellido,
				fecha_nacimiento: form.fecha_nacimiento || null,
				sexo: form.sexo,
				id_zona: form.id_zona ? parseInt(form.id_zona) : null
			})
			.select()
			.single();

		if (pacienteErr) {
			error = 'Error al crear paciente: ' + pacienteErr.message;
			submitting = false;
			return;
		}

		const { data: caso, error: casoErr } = await supabase
			.from('caso')
			.insert({
				id_paciente: paciente.id_paciente,
				id_enfermedad: parseInt(form.id_enfermedad),
				id_centro: parseInt(form.id_centro),
				id_usuario: usuarioId,
				estado: form.estado,
				confirmacion: form.confirmacion,
				fecha_inicio_sintomas: form.fecha_inicio_sintomas || null
			})
			.select()
			.single();

		if (casoErr) {
			error = 'Error al crear caso: ' + casoErr.message;
			submitting = false;
			return;
		}

		if (form.sintomasSeleccionados.length > 0) {
			const casoSintomas = form.sintomasSeleccionados.map((id_sintoma) => ({
				id_caso: caso.id_caso,
				id_sintoma,
				fecha_aparicion: form.fecha_inicio_sintomas || null
			}));

			const { error: csErr } = await supabase.from('caso_sintoma').insert(casoSintomas);
			if (csErr) {
				console.error('Error inserting caso_sintoma:', csErr);
			}
		}

		success = true;
		submitting = false;

		setTimeout(() => {
			goto('/casos');
		}, 2000);
	}
</script>

<svelte:head>
	<title>Nuevo Caso - SaludSCZ</title>
</svelte:head>

<h1>Registrar Nuevo Caso</h1>
<p style="color: var(--color-text-muted); margin-bottom: 2rem;">
	Complete el formulario para registrar un caso de enfermedad tropical
</p>

{#if success}
	<div class="card" style="text-align: center; padding: 3rem;">
		<div style="font-size: 3rem; margin-bottom: 1rem;">&#9989;</div>
		<h2 style="color: var(--color-verde); margin-bottom: 0.5rem;">Caso Registrado</h2>
		<p style="color: var(--color-text-muted);">Redirigiendo al historial de casos...</p>
	</div>
{:else if loading}
	<div class="loading">Cargando formulario...</div>
{:else}
	{#if error}
		<div class="error" style="margin-bottom: 1rem;">{error}</div>
	{/if}

	<form onsubmit={(e) => { e.preventDefault(); handleSubmit(); }}>
		<div class="grid-2">
			<div class="card">
				<div class="card-header">Datos del Paciente</div>

				<div class="form-group">
					<label for="nombre">Nombre *</label>
					<input id="nombre" type="text" bind:value={form.nombre} required />
				</div>

				<div class="form-group">
					<label for="apellido">Apellido *</label>
					<input id="apellido" type="text" bind:value={form.apellido} required />
				</div>

				<div class="grid-2">
					<div class="form-group">
						<label for="fnac">Fecha de Nacimiento</label>
						<input id="fnac" type="date" bind:value={form.fecha_nacimiento} />
					</div>
					<div class="form-group">
						<label for="sexo">Sexo</label>
						<select id="sexo" bind:value={form.sexo}>
							<option value="M">Masculino</option>
							<option value="F">Femenino</option>
							<option value="O">Otro</option>
						</select>
					</div>
				</div>

				<div class="form-group">
					<label for="zona">Zona de Residencia</label>
					<select id="zona" bind:value={form.id_zona}>
						<option value="">Seleccionar zona...</option>
						{#each zonas as z}
							<option value={z.id_zona}>{z.nombre} (Distrito {z.distrito ?? '?'})</option>
						{/each}
					</select>
				</div>
			</div>

			<div class="card">
				<div class="card-header">Datos del Caso</div>

				<div class="form-group">
					<label for="enf">Enfermedad *</label>
					<select id="enf" bind:value={form.id_enfermedad} required>
						<option value="">Seleccionar enfermedad...</option>
						{#each enfermedades as e}
							<option value={e.id_enfermedad}>{e.nombre} ({e.tipo})</option>
						{/each}
					</select>
				</div>

				<div class="form-group">
					<label for="centro">Centro de Salud *</label>
					<select id="centro" bind:value={form.id_centro} required>
						<option value="">Seleccionar centro...</option>
						{#each centros as c}
							<option value={c.id_centro}>{c.nombre}</option>
						{/each}
					</select>
				</div>

				<div class="grid-2">
					<div class="form-group">
						<label for="estado">Estado</label>
						<select id="estado" bind:value={form.estado}>
							<option value="sospechoso">Sospechoso</option>
							<option value="confirmado">Confirmado</option>
							<option value="descartado">Descartado</option>
							<option value="recuperado">Recuperado</option>
						</select>
					</div>
					<div class="form-group">
						<label for="confirmacion">Confirmacion</label>
						<select id="confirmacion" bind:value={form.confirmacion}>
							<option value="clinica">Clinica</option>
							<option value="laboratorio">Laboratorio</option>
							<option value="epidemiologica">Epidemiologica</option>
						</select>
					</div>
				</div>

				<div class="form-group">
					<label for="fsint">Fecha Inicio Sintomas</label>
					<input id="fsint" type="date" bind:value={form.fecha_inicio_sintomas} />
				</div>
			</div>
		</div>

		<div class="card" style="margin-top: 1rem;">
			<div class="card-header">Sintomas ({form.sintomasSeleccionados.length} seleccionados)</div>
			<div class="sintomas-grid">
				{#each sintomas as s}
					<label class="sintoma-chip" class:selected={form.sintomasSeleccionados.includes(s.id_sintoma)}>
						<input
							type="checkbox"
							checked={form.sintomasSeleccionados.includes(s.id_sintoma)}
							onchange={() => toggleSintoma(s.id_sintoma)}
						/>
						<span>{s.nombre}</span>
						<span class="gravedad" class:grave={s.nivel_gravedad === 'grave'} class:moderado={s.nivel_gravedad === 'moderado'}>
							{s.nivel_gravedad}
						</span>
					</label>
				{/each}
			</div>
		</div>

		<div style="margin-top: 1.5rem; display: flex; gap: 1rem; justify-content: flex-end;">
			<a href="/casos" class="btn btn-outline">Cancelar</a>
			<button type="submit" class="btn btn-primary" disabled={submitting}>
				{#if submitting}Registrando...{:else}Registrar Caso{/if}
			</button>
		</div>
	</form>
{/if}

<style>
	.sintomas-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
		gap: 0.5rem;
	}

	.sintoma-chip {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		padding: 0.5rem 0.75rem;
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius);
		cursor: pointer;
		transition: all 0.2s;
		font-size: 0.85rem;
	}

	.sintoma-chip input {
		width: auto;
	}

	.sintoma-chip.selected {
		border-color: var(--color-primary);
		background: rgba(56, 189, 248, 0.1);
	}

	.sintoma-chip:hover {
		border-color: var(--color-primary);
	}

	.gravedad {
		margin-left: auto;
		font-size: 0.7rem;
		padding: 0.1rem 0.4rem;
		border-radius: 4px;
		background: rgba(148, 163, 184, 0.2);
		color: var(--color-text-muted);
	}

	.gravedad.grave {
		background: rgba(239, 68, 68, 0.2);
		color: var(--color-rojo);
	}

	.gravedad.moderado {
		background: rgba(249, 115, 22, 0.2);
		color: var(--color-naranja);
	}
</style>
