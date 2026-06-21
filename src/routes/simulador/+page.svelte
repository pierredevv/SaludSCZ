<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { supabase } from '$lib/supabase';

	interface Disease {
		id_enfermedad: number;
		nombre: string;
		tipo: string;
	}

	interface Zone {
		id_zona: number;
		nombre: string;
		dm_id: number;
		poblacion: number;
	}

	interface Center {
		id_centro: number;
		nombre: string;
		id_zona: number;
	}

	interface LogEntry {
		id: string;
		time: string;
		type: 'info' | 'success' | 'warning' | 'error';
		message: string;
	}

	let diseases = $state<Disease[]>([]);
	let zones = $state<Zone[]>([]);
	let centers = $state<Center[]>([]);
	let defaultUserId = $state<number | null>(null);

	let selectedDiseaseId = $state<number>(0);
	let selectedZoneId = $state<number | null>(null); // null means Random
	let caseState = $state<'sospechoso' | 'confirmado'>('sospechoso');
	let caseConfirmation = $state<'clinica' | 'laboratorio' | 'nexo'>('clinica');
	let isSimulating = $state(false);
	let simulationInterval = $state(3); // seconds
	let totalSimulated = $state(0);
	let simulationTimer: any = null;

	let logs = $state<LogEntry[]>([]);
	let consoleContainer = $state<HTMLDivElement | null>(null);
	let loading = $state(true);
	let testInsertResult = $state<string | null>(null);

	const FIRST_NAMES = [
		'Alejandro', 'Mariela', 'Carlos', 'Silvia', 'Pedro', 'Gabriela', 'Jorge', 'Patricia',
		'David', 'Andrea', 'Fernando', 'Luisa', 'Mauricio', 'Camila', 'Roberto', 'Natalia',
		'Gustavo', 'Lucia', 'Hugo', 'Roxana', 'Marcelo', 'Liliana', 'Ricardo', 'Beatriz',
		'Ronald', 'Claudia', 'Rodrigo', 'Vanesa', 'Oscar', 'Diana', 'Mario', 'Elizabeth'
	];

	const LAST_NAMES = [
		'Flores', 'Mamani', 'Vargas', 'Justiniano', 'Ortiz', 'Pinto', 'Chavez', 'Rojas',
		'Mendoza', 'Suarez', 'Guzman', 'Gutierrez', 'Soliz', 'Torrico', 'Mercado', 'Aguilar',
		'Cuellar', 'Roca', 'Alvarez', 'Salvatierra', 'Castillo', 'Villagomez', 'Saucedo', 'Banegas',
		'Zelaya', 'Terrazas', 'Paz', 'Baldivieso', 'Cardozo', 'Arce', 'Ribera', 'Serrano'
	];

	onMount(async () => {
		try {
			const [disRes, zoneRes, cenRes, userRes] = await Promise.all([
				supabase.from('enfermedad').select('id_enfermedad, nombre, tipo'),
				supabase.from('zona').select('id_zona, nombre, dm_id, poblacion').order('dm_id'),
				supabase.from('centro_salud').select('id_centro, nombre, id_zona'),
				supabase.from('usuario').select('id_usuario').limit(1)
			]);

			diseases = disRes.data ?? [];
			zones = zoneRes.data ?? [];
			centers = cenRes.data ?? [];
			if (userRes.data && userRes.data.length > 0) {
				defaultUserId = userRes.data[0].id_usuario;
			} else {
				defaultUserId = 1; // Fallback
			}

			if (diseases.length > 0) {
				selectedDiseaseId = diseases[0].id_enfermedad;
			}
			loading = false;
			addLog('info', '🧬 Simulador inicializado. Listo para generar transmisiones.');
		} catch (e: any) {
			addLog('error', `Error de conexión: ${e.message}`);
			loading = false;
		}
	});

	onDestroy(() => {
		stopSimulation();
	});

	function addLog(type: LogEntry['type'], message: string) {
		const now = new Date();
		const timeStr = now.toTimeString().split(' ')[0];
		logs = [...logs, { id: Math.random().toString(), time: timeStr, type, message }];
		
		// Scroll to bottom
		setTimeout(() => {
			if (consoleContainer) {
				consoleContainer.scrollTop = consoleContainer.scrollHeight;
			}
		}, 50);
	}

	function startSimulation() {
		if (isSimulating) return;
		isSimulating = true;
		addLog('warning', `⚡ Simulación iniciada. Frecuencia: 1 caso cada ${simulationInterval}s.`);
		runSimulationStep();
	}

	function runSimulationStep() {
		if (!isSimulating) return;
		generateCase();
		simulationTimer = setTimeout(runSimulationStep, simulationInterval * 1000);
	}

	function stopSimulation() {
		if (!isSimulating) return;
		isSimulating = false;
		if (simulationTimer) {
			clearTimeout(simulationTimer);
			simulationTimer = null;
		}
		addLog('warning', '🛑 Simulación detenida.');
	}

	function clearLogs() {
		logs = [];
		totalSimulated = 0;
	}

	async function generateCase() {
		if (diseases.length === 0 || zones.length === 0) return;

		// 1. Pick disease
		const disease = diseases.find(d => d.id_enfermedad === selectedDiseaseId) || diseases[0];

		// 2. Pick zone
		let zone: Zone;
		if (selectedZoneId === null) {
			// Random weighted zone (Plan 3000, Villa 1ro de Mayo and Pampa de la Isla are larger, so we favor them slightly)
			const randVal = Math.random();
			if (randVal < 0.25) {
				zone = zones.find(z => z.dm_id === 8) || zones[Math.floor(Math.random() * zones.length)]; // Plan 3000
			} else if (randVal < 0.45) {
				zone = zones.find(z => z.dm_id === 7) || zones[Math.floor(Math.random() * zones.length)]; // Villa 1ro de Mayo
			} else if (randVal < 0.60) {
				zone = zones.find(z => z.dm_id === 6) || zones[Math.floor(Math.random() * zones.length)]; // Pampa de la Isla
			} else {
				zone = zones[Math.floor(Math.random() * zones.length)];
			}
		} else {
			zone = zones.find(z => z.id_zona === selectedZoneId) || zones[0];
		}

		// 3. Find center in that zone or default to nearest
		let zoneCenters = centers.filter(c => c.id_zona === zone.id_zona);
		let center: Center;
		if (zoneCenters.length > 0) {
			center = zoneCenters[Math.floor(Math.random() * zoneCenters.length)];
		} else {
			// Find centers in neighboring zones (or just pick any center)
			center = centers[Math.floor(Math.random() * centers.length)] || { id_centro: 1, nombre: 'Hospital Japonés', id_zona: 1 };
		}

		// 4. Generate random patient details
		const fn = FIRST_NAMES[Math.floor(Math.random() * FIRST_NAMES.length)];
		const ln = LAST_NAMES[Math.floor(Math.random() * LAST_NAMES.length)];
		const name = fn;
		const surname = ln;
		const birthDate = new Date();
		birthDate.setFullYear(birthDate.getFullYear() - Math.floor(Math.random() * 60 + 5));
		const birthDateStr = birthDate.toISOString().split('T')[0];
		const sex = Math.random() > 0.5 ? 'M' : 'F';
		const phone = '7' + Math.floor(1000000 + Math.random() * 9000000).toString().substring(0, 7);
		const address = `UV ${zone.dm_id * 10 + Math.floor(Math.random() * 9 + 1)}, Barrio ${surname}, C/ Principal`;

		addLog('info', `🧪 Generando paciente: ${name} ${surname} en ${zone.nombre}...`);

		// Insert Patient
		const { data: patData, error: patErr } = await supabase
			.from('paciente')
			.insert({
				nombre: name,
				apellido: surname,
				fecha_nacimiento: birthDateStr,
				sexo: sex,
				telefono: phone,
				direccion: address,
				id_zona: zone.id_zona
			})
			.select('id_paciente')
			.single();

		if (patErr) {
			addLog('error', `Error insertando paciente: ${patErr.message}`);
			return;
		}

		const patientId = patData.id_paciente;

		// 5. Generate case
		const symptomsOffset = Math.floor(Math.random() * 5 + 2); // 2 to 7 days ago
		const regDate = new Date().toISOString().split('T')[0];
		const onsetDate = new Date();
		onsetDate.setDate(onsetDate.getDate() - symptomsOffset);
		const onsetDateStr = onsetDate.toISOString().split('T')[0];

		const { data: caseData, error: caseErr } = await supabase
			.from('caso')
			.insert({
				fecha_registro: regDate,
				fecha_inicio_sintomas: onsetDateStr,
				estado: caseState,
				confirmacion: caseConfirmation,
				id_paciente: patientId,
				id_enfermedad: disease.id_enfermedad,
				id_centro: center.id_centro,
				id_usuario: defaultUserId
			})
			.select('id_caso')
			.single();

		if (caseErr) {
			addLog('error', `Error insertando caso: ${caseErr.message}`);
			return;
		}

		totalSimulated++;
		addLog('success', `🚨 CASO CONFIRMADO: [${disease.nombre}] registrado en ${center.nombre} (${zone.nombre}). ID Caso: ${caseData.id_caso}`);
	}
</script>

<svelte:head>
	<title>Simulador de Brotes - SaludSCZ</title>
</svelte:head>

<div class="simulator-header" style="margin-bottom: 1.5rem; display: flex; align-items: center; justify-content: space-between;">
	<div>
		<h1>⚡ Simulador de Brotes en Tiempo Real</h1>
		<p style="color: var(--color-text-muted);">
			Genera e inyecta transmisiones y casos clínicos dinámicos para demostrar el funcionamiento de la base de datos distribuida y las alertas de SaludSCZ.
		</p>
	</div>
	<div class="badge" style="background: rgba(56,189,248,0.15); border: 1px solid var(--color-primary); padding: 0.5rem 1rem; border-radius: var(--radius); font-size: 0.9rem; color: var(--color-primary); display: flex; align-items: center; gap: 0.5rem;">
		<span class="pulsar-dot" class:active={isSimulating}></span>
		<span>{isSimulating ? 'SIMULANDO' : 'INACTIVO'}</span>
	</div>
</div>

{#if loading}
	<div class="loading">Cargando base de datos de control...</div>
{:else}
	<div class="grid-3" style="align-items: start; margin-bottom: 2rem;">
		<!-- PANEL DE CONTROL -->
		<div class="card" style="grid-column: span 1; display: flex; flex-direction: column; gap: 1rem;">
			<div class="card-header">⚙️ Ajustes del Brote</div>
			
			<div class="form-group">
				<label for="sim-disease">Enfermedad Tropical:</label>
				<select id="sim-disease" bind:value={selectedDiseaseId}>
					{#each diseases as d}
						<option value={d.id_enfermedad}>{d.nombre} ({d.tipo})</option>
					{/each}
				</select>
			</div>

			<div class="form-group">
				<label for="sim-zone">Foco del Brote (Zona/Distrito):</label>
				<select id="sim-zone" bind:value={selectedZoneId}>
					<option value={null}>Aleatorio (Distribuido)</option>
					{#each zones as z}
						<option value={z.id_zona}>{z.nombre} (Población: {z.poblacion.toLocaleString()})</option>
					{/each}
				</select>
			</div>

			<div class="form-group">
				<label for="sim-state">Estado Inicial:</label>
				<select id="sim-state" bind:value={caseState}>
					<option value="sospechoso">Sospechoso</option>
					<option value="confirmado">Confirmado</option>
				</select>
			</div>

			<div class="form-group">
				<label for="sim-confirmation">Método de Confirmación:</label>
				<select id="sim-confirmation" bind:value={caseConfirmation}>
					<option value="clinica">Criterio Clínico</option>
					<option value="laboratorio">Prueba de Laboratorio</option>
					<option value="nexo">Nexo Epidemiológico</option>
				</select>
			</div>

			<div class="form-group">
				<label for="sim-interval">Frecuencia (Segundos): <strong>{simulationInterval}s</strong></label>
				<input id="sim-interval" type="range" min="1" max="15" bind:value={simulationInterval} disabled={isSimulating} style="padding: 0; height: 6px; background: var(--color-surface-2);" />
			</div>

			<div style="display: flex; gap: 0.5rem; margin-top: 1rem;">
				{#if !isSimulating}
					<button class="btn btn-primary" onclick={startSimulation} style="flex: 1; justify-content: center; gap: 0.5rem; box-shadow: 0 0 15px rgba(56, 189, 248, 0.4);">
						▶️ Iniciar
					</button>
				{:else}
					<button class="btn btn-outline" onclick={stopSimulation} style="flex: 1; justify-content: center; background: var(--color-rojo); border-color: var(--color-rojo); color: #fff;">
						⏸️ Detener
					</button>
				{/if}
				<button class="btn btn-outline" onclick={generateCase} disabled={isSimulating} style="flex: 1; justify-content: center;">
					⚡ Inyectar Uno
				</button>
			</div>
		</div>

		<!-- CONSOLA DE TELEMETRIA -->
		<div class="card" style="grid-column: span 2; display: flex; flex-direction: column; height: 535px; background: #070d19; border-color: #1e293b;">
			<div class="card-header" style="display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #1e293b; padding-bottom: 0.5rem; margin-bottom: 0.5rem;">
				<span style="color: #60a5fa; font-family: monospace; font-size: 1rem;">💻 Live Telemetry Stream</span>
				<div style="display: flex; gap: 0.5rem;">
					<span style="color: var(--color-text-muted); font-size: 0.85rem; font-family: monospace;">Inyectados: <strong style="color: var(--color-primary);">{totalSimulated}</strong></span>
					<button onclick={clearLogs} style="background: none; border: none; color: var(--color-text-muted); cursor: pointer; font-size: 0.8rem; font-family: monospace; hover: color: #fff;">[Limpiar]</button>
				</div>
			</div>
			
			<div class="console-body" bind:this={consoleContainer} style="flex: 1; overflow-y: auto; font-family: monospace; font-size: 0.85rem; padding: 0.5rem; display: flex; flex-direction: column; gap: 0.4rem; color: #a1a1aa;">
				{#each logs as log}
					<div class="log-line {log.type}">
						<span class="log-time" style="color: #64748b;">[{log.time}]</span>
						<span class="log-msg">{log.message}</span>
					</div>
				{/each}
				{#if logs.length === 0}
					<div style="display: flex; height: 100%; flex-direction: column; align-items: center; justify-content: center; color: #4b5563; font-style: italic;">
						<span>Consola vacía. Inicia la simulación para ver la telemetría en tiempo real.</span>
					</div>
				{/if}
			</div>
		</div>
	</div>

	<!-- PANEL DE INSTRUCCIONES Y CASOS DE USO -->
	<div class="card" style="margin-top: 1.5rem;">
		<div class="card-header">🎮 Instrucciones del Simulador y Casos de Uso</div>
		<div style="font-size: 0.9rem; color: var(--color-text-muted); display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.5rem; margin-top: 0.5rem;">
			<div>
				<h4 style="color: var(--color-text); margin-bottom: 0.4rem;">1. Configuración del Caso</h4>
				<p>Define los parámetros epidemiológicos (enfermedad tropical, foco/distrito epicentro y método de confirmación) desde el panel de control lateral.</p>
			</div>
			<div>
				<h4 style="color: var(--color-text); margin-bottom: 0.4rem;">2. Inyección de Transmisiones</h4>
				<p>Usa <strong>"Inyectar Uno"</strong> para generar un evento aislado, o presiona <strong>"Iniciar"</strong> para automatizar un flujo de casos a intervalos regulares y evaluar la respuesta del sistema.</p>
			</div>
			<div>
				<h4 style="color: var(--color-text); margin-bottom: 0.4rem;">3. Telemetría y Monitoreo</h4>
				<p>Monitorea los reportes en la consola de telemetría. Te sugerimos abrir la vista de <strong>Mapa</strong> o <strong>Dashboard</strong> en paralelo para ver la sincronización inmediata de gráficos y heatmaps.</p>
			</div>
		</div>
	</div>
{/if}

<style>
	.pulsar-dot {
		display: inline-block;
		width: 10px;
		height: 10px;
		background: #64748b;
		border-radius: 50%;
	}

	.pulsar-dot.active {
		background: var(--color-verde);
		animation: pulse 1.5s infinite;
		box-shadow: 0 0 8px var(--color-verde);
	}

	@keyframes pulse {
		0% { transform: scale(0.9); opacity: 0.8; }
		50% { transform: scale(1.2); opacity: 1; }
		100% { transform: scale(0.9); opacity: 0.8; }
	}

	.log-line.success { color: var(--color-verde); }
	.log-line.warning { color: var(--color-amarillo); }
	.log-line.error { color: var(--color-rojo); }
	.log-line.info { color: #60a5fa; }
</style>
