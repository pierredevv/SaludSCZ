<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import type { Sintoma, CentroSalud, Zona } from '$lib/types';

	let sintomas = $state<Sintoma[]>([]);
	let centros = $state<CentroSalud[]>([]);
	let zones = $state<Zona[]>([]);
	let loading = $state(true);
	let step = $state(1);
	let selectedSintomas = $state<number[]>([]);
	let resultado = $state<any>(null);
	let centrosCercanos = $state<any[]>([]);
	let userLat = $state<number | null>(null);
	let userLng = $state<number | null>(null);

	const SIGNOS_ALARMA = ['Petecias', 'Hemorragia nasal', 'Hemorragia gingival', 'Hematemesis', 'Melena', 'Vomito'];
	const SINTOMAS_DENGUE = ['Fiebre', 'Dolor retroocular', 'Dolor muscular', 'Dolor articular', 'Cefalea', 'Exantema cutaneo'];

	onMount(async () => {
		const [sintomasRes, centrosRes, zonasRes] = await Promise.all([
			supabase.from('sintoma').select('*').order('nombre'),
			supabase.from('centro_salud').select('*'),
			supabase.from('zona').select('*')
		]);
		sintomas = sintomasRes.data ?? [];
		centros = centrosRes.data ?? [];
		zones = zonasRes.data ?? [];
		loading = false;
	});

	function toggleSintoma(id: number) {
		if (selectedSintomas.includes(id)) {
			selectedSintomas = selectedSintomas.filter(s => s !== id);
		} else {
			selectedSintomas = [...selectedSintomas, id];
		}
	}

	function evaluar() {
		const selNames = selectedSintomas.map(id => sintomas.find(s => s.id_sintoma === id)?.nombre ?? '');
		const tieneAlarma = selNames.some(n => SIGNOS_ALARMA.includes(n));
		const sintomasDengue = selNames.filter(n => SINTOMAS_DENGUE.includes(n)).length;
		const tieneFiebre = selNames.includes('Fiebre');

		if (tieneAlarma) {
			resultado = {
				nivel: 'grave', color: '#ef4444', titulo: '⚠️ SIGNOS DE ALARMA DETECTADOS',
				descripcion: 'Los síntomas seleccionados incluyen signos de alarma de dengue grave. Acuda INMEDIATAMENTE al centro de salud más cercano.',
				recomendaciones: [
					'NO se automedique, especialmente NO tome aspirina ni ibuprofeno.',
					'Acuda al centro de salud o emergencias más cercano de inmediato.',
					'Manténgase hidratado con suero de rehidratación oral.',
					'Si presenta vómitos persistentes o sangrado, llame a emergencias.'
				]
			};
		} else if (tieneFiebre && sintomasDengue >= 3) {
			resultado = {
				nivel: 'moderado', color: '#f97316', titulo: '🟠 Sospecha de Dengue Clásico',
				descripcion: 'Sus síntomas son compatibles con dengue clásico. Consulte con un profesional de salud para confirmación.',
				recomendaciones: [
					'Tome paracetamol (acetaminofén) para la fiebre. NO tome aspirina ni ibuprofeno.',
					'Beba abundantes líquidos (agua, jugos, suero oral).',
					'Descanse y monitoree su temperatura.',
					'Si aparecen signos de alarma (sangrado, dolor abdominal intenso, vómitos), acuda a emergencias.',
					'Use repelente y mosquitero para evitar contagiar a otros.'
				]
			};
		} else if (tieneFiebre) {
			resultado = {
				nivel: 'leve', color: '#eab308', titulo: '🟡 Cuadro Febril — Observación',
				descripcion: 'Presenta fiebre pero sin suficientes síntomas característicos de dengue. Monitoree su evolución.',
				recomendaciones: [
					'Mantenga reposo e hidratación adecuada.',
					'Tome paracetamol si la fiebre es alta (>38.5°C).',
					'Si los síntomas persisten más de 48 horas, consulte a un médico.',
					'Elimine criaderos de mosquitos en su hogar.'
				]
			};
		} else {
			resultado = {
				nivel: 'leve', color: '#22c55e', titulo: '✅ Bajo Riesgo',
				descripcion: 'Los síntomas seleccionados no sugieren un cuadro de dengue activo. Manténgase vigilante.',
				recomendaciones: [
					'Mantenga las medidas de prevención (repelente, mosquitero).',
					'Si desarrolla fiebre, repita esta evaluación.',
					'Elimine agua estancada en su hogar.',
					'Consulte si los síntomas empeoran.'
				]
			};
		}

		buscarCentrosCercanos();
		step = 3;
	}

	function buscarCentrosCercanos() {
		if (!navigator.geolocation) return;
		navigator.geolocation.getCurrentPosition((pos) => {
			userLat = pos.coords.latitude;
			userLng = pos.coords.longitude;

			const centrosConDist = centros.map(c => {
				const zone = zones.find(z => z.id_zona === c.id_zona);
				if (!zone?.latitud || !zone?.longitud) return { ...c, distancia: 999, lat: 0, lng: 0 };
				const dist = haversine(userLat!, userLng!, zone.latitud, zone.longitud);
				return { ...c, distancia: dist, lat: zone.latitud, lng: zone.longitud };
			}).sort((a, b) => a.distancia - b.distancia);

			centrosCercanos = centrosConDist.slice(0, 3);
		}, () => {
			centrosCercanos = [];
		});
	}

	function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
		const R = 6371;
		const dLat = (lat2 - lat1) * Math.PI / 180;
		const dLon = (lon2 - lon1) * Math.PI / 180;
		const a = Math.sin(dLat/2)**2 + Math.cos(lat1*Math.PI/180) * Math.cos(lat2*Math.PI/180) * Math.sin(dLon/2)**2;
		return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
	}

	function reiniciar() {
		selectedSintomas = [];
		resultado = null;
		centrosCercanos = [];
		step = 1;
	}
</script>

<svelte:head>
	<title>Autodiagnóstico - SaludSCZ</title>
</svelte:head>

<h1>Evaluación de Síntomas</h1>
<p style="color: var(--color-text-muted); margin-bottom: 1.5rem;">
	Herramienta de triage digital. Seleccione sus síntomas para recibir una orientación inicial.
	<strong>Esta herramienta NO reemplaza la consulta médica.</strong>
</p>

{#if loading}
	<div class="loading">Cargando...</div>
{:else if step === 1}
	<div class="card" style="margin-bottom: 1.5rem;">
		<div class="card-header">Paso 1: Seleccione sus síntomas</div>
		<div class="sintomas-grid">
			{#each sintomas as s}
				<button
					class="sintoma-btn"
					class:selected={selectedSintomas.includes(s.id_sintoma)}
					class:alarma={SIGNOS_ALARMA.includes(s.nombre)}
					onclick={() => toggleSintoma(s.id_sintoma)}
				>
					<span class="sintoma-nombre">{s.nombre}</span>
					<span class="sintoma-desc">{s.descripcion ?? ''}</span>
					{#if SIGNOS_ALARMA.includes(s.nombre)}
						<span class="alarma-tag">⚠ Signo de alarma</span>
					{/if}
				</button>
			{/each}
		</div>
	</div>

	<div style="display: flex; gap: 1rem;">
		<button class="btn btn-primary" onclick={() => { step = 2; }} disabled={selectedSintomas.length === 0}>
			Continuar ({selectedSintomas.length} síntomas)
		</button>
		<button class="btn btn-outline" onclick={reiniciar}>Limpiar</button>
	</div>
{:else if step === 2}
	<div class="card" style="margin-bottom: 1.5rem;">
		<div class="card-header">Paso 2: Confirmar síntomas</div>
		<p style="color: var(--color-text-muted); margin-bottom: 1rem;">Usted seleccionó los siguientes síntomas:</p>
		<div style="display: flex; flex-wrap: wrap; gap: 0.5rem; margin-bottom: 1rem;">
			{#each selectedSintomas as id}
				{@const s = sintomas.find(s => s.id_sintoma === id)}
				{#if s}
					<span class="badge" style="background: {SIGNOS_ALARMA.includes(s.nombre) ? '#ef4444' : 'var(--color-primary)'}; color: #fff; font-size: 0.85rem; padding: 0.3rem 0.8rem;">
						{s.nombre}
					</span>
				{/if}
			{/each}
		</div>
		<div style="display: flex; gap: 1rem;">
			<button class="btn btn-primary" onclick={evaluar}>Evaluar</button>
			<button class="btn btn-outline" onclick={() => { step = 1; }}>Volver</button>
		</div>
	</div>
{:else if step === 3 && resultado}
	<div class="card resultado-card" style="border-left: 4px solid {resultado.color}; margin-bottom: 1.5rem;">
		<h2 style="color: {resultado.color}; margin-bottom: 0.5rem;">{resultado.titulo}</h2>
		<p style="color: var(--color-text-muted); margin-bottom: 1rem;">{resultado.descripcion}</p>
		<div class="card-header" style="font-size: 0.95rem;">Recomendaciones:</div>
		<ul class="recomendaciones">
			{#each resultado.recomendaciones as rec}
				<li>{rec}</li>
			{/each}
		</ul>
	</div>

	{#if centrosCercanos.length > 0}
		<div class="card" style="margin-bottom: 1.5rem;">
			<div class="card-header">🏥 Centros de Salud más Cercanos</div>
			<div class="centros-grid">
				{#each centrosCercanos as c}
					<div class="centro-item">
						<h4>{c.nombre}</h4>
						<p>{c.tipo ?? 'Centro de Salud'} — {c.direccion ?? 'Sin dirección'}</p>
						{#if c.telefono}<p style="color: var(--color-primary);">📞 {c.telefono}</p>{/if}
						<p style="font-weight: 600; color: var(--color-primary);">📍 {c.distancia.toFixed(1)} km</p>
						<a href="https://www.google.com/maps/dir/?api=1&destination={c.lat},{c.lng}" target="_blank" class="btn btn-outline" style="margin-top: 0.5rem; font-size: 0.8rem;">
							Cómo llegar
						</a>
					</div>
				{/each}
			</div>
		</div>
	{/if}

	<button class="btn btn-primary" onclick={reiniciar}>Nueva Evaluación</button>
{/if}

<style>
	.sintomas-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
		gap: 0.75rem;
	}

	.sintoma-btn {
		display: flex; flex-direction: column; gap: 0.2rem;
		padding: 0.75rem; border-radius: var(--radius);
		background: var(--color-surface-2); border: 2px solid transparent;
		color: var(--color-text); cursor: pointer; text-align: left;
		transition: all 0.2s;
	}

	.sintoma-btn:hover { border-color: var(--color-primary); }
	.sintoma-btn.selected { border-color: var(--color-primary); background: rgba(56, 189, 248, 0.1); }
	.sintoma-btn.alarma.selected { border-color: var(--color-rojo); background: rgba(239, 68, 68, 0.1); }

	.sintoma-nombre { font-weight: 600; font-size: 0.9rem; }
	.sintoma-desc { font-size: 0.75rem; color: var(--color-text-muted); }
	.alarma-tag { font-size: 0.7rem; color: var(--color-rojo); font-weight: 600; margin-top: 0.2rem; }

	.recomendaciones {
		list-style: none; padding: 0;
	}

	.recomendaciones li {
		padding: 0.5rem 0; border-bottom: 1px solid var(--color-border);
		color: var(--color-text-muted); font-size: 0.9rem;
	}

	.recomendaciones li::before {
		content: '→ '; color: var(--color-primary); font-weight: 600;
	}

	.centros-grid {
		display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 1rem;
	}

	.centro-item {
		padding: 1rem; background: var(--color-surface-2); border-radius: var(--radius);
	}

	.centro-item h4 { margin-bottom: 0.3rem; }
	.centro-item p { font-size: 0.85rem; color: var(--color-text-muted); margin-bottom: 0.2rem; }
</style>
