<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { supabase } from '$lib/supabase';
	import type { Zona, AlertaActiva, TasaIncidencia, CentroSalud } from '$lib/types';
	import { ALERT_COLORS, DISEASE_COLORS } from '$lib/types';

	let map = $state<any>(null);
	let zones = $state<Zona[]>([]);
	let alerts = $state<AlertaActiva[]>([]);
	let tasas = $state<TasaIncidencia[]>([]);
	let centros = $state<CentroSalud[]>([]);
	let resumenZonas = $state<any[]>([]);
	let enfermedades = $state<string[]>([]);
	let realTimeChannel: any = null;
	let activeToast = $state<{
		show: boolean;
		enfermedad: string;
		zona: string;
		latitud: number;
		longitud: number;
	}>({ show: false, enfermedad: '', zona: '', latitud: 0, longitud: 0 });

	const DISEASE_NAMES_BY_ID: Record<number, string> = {
		1: 'Dengue',
		2: 'Chikungunya',
		3: 'Zika',
		4: 'Leishmaniasis',
		5: 'Malaria'
	};
	let distritosGeo = $state<any>(null);
	let loading = $state(true);
	let selectedZone = $state<Zona | null>(null);
	let mapContainer = $state<HTMLDivElement | null>(null);
	let L: any = null;
	let districtLayer = $state<any>(null);
	let markerLayer = $state<any>(null);
	let heatLayer = $state<any>(null);
	let centrosLayer = $state<any>(null);
	let showDistricts = $state(true);
	let showMarkers = $state(true);
	let showHeatmap = $state(false);
	let showCentros = $state(false);
	let filtroEnfermedad = $state('');

	const DISTRICT_COLORS: Record<string, string> = {
		muy_alta: '#ef4444',
		alta: '#f97316',
		moderada: '#eab308',
		baja: '#22c55e'
	};

	const DISTRICT_NAMES: Record<number, string> = {
		1: 'DM1 - Piraí',
		2: 'DM2 - Norte Interno',
		3: 'DM3 - Estación Argentina',
		4: 'DM4 - El Pari',
		5: 'DM5 - Norte',
		6: 'DM6 - Pampa de la Isla / El Dorado',
		7: 'DM7 - Villa 1ro de Mayo',
		8: 'DM8 - Plan 3000',
		9: 'DM9 - Palmasola / Sur',
		10: 'DM10 - El Bajío',
		11: 'DM11 - Centro',
		12: 'DM12 - Nuevo Palmar / El Palmar del Oratorio',
		13: 'DM U/R 13 - Distrito Urbano/Rural - El Palmar',
		14: 'DM14 - Área Urbana Paurito',
		15: 'DM15 - Área Urbana Montero Hoyos',
		16: 'DI - Distrito Industrial'
	};

	onMount(async () => {
		const [zonesRes, alertsRes, tasasRes, geoRes, centrosRes, resumenRes] = await Promise.all([
			supabase.from('zona').select('*'),
			supabase.from('v_alertas_activas').select('*'),
			supabase.from('v_tasa_incidencia').select('*'),
			fetch('/geojson/distritos.geojson'),
			supabase.from('centro_salud').select('*'),
			supabase.from('v_resumen_zonas').select('*')
		]);

		zones = zonesRes.data ?? [];
		alerts = (alertsRes.data ?? []) as unknown as AlertaActiva[];
		tasas = (tasasRes.data ?? []) as unknown as TasaIncidencia[];
		centros = centrosRes.data ?? [];
		resumenZonas = resumenRes.data ?? [];
		enfermedades = [...new Set(resumenZonas.map((r: any) => r.enfermedad as string))];

		if (geoRes.ok) {
			const text = await geoRes.text();
			try {
				distritosGeo = JSON.parse(text);
				console.log('GeoJSON cargado:', distritosGeo.features?.length, 'features');
			} catch (e) {
				console.error('Error parseando GeoJSON:', e);
			}
		} else {
			console.error('Error cargando GeoJSON:', geoRes.status, geoRes.statusText);
		}

		loading = false;

		await tick();
		await initMap();

		// Real-time listener for new cases
		realTimeChannel = supabase
			.channel('map-cases-channel')
			.on(
				'postgres_changes',
				{ event: 'INSERT', schema: 'public', table: 'caso' },
				async (payload) => {
					console.log('Realtime case received:', payload);
					const newCase = payload.new;
					const center = centros.find((c) => c.id_centro === newCase.id_centro);
					const zone = zones.find((z) => z.id_zona === center?.id_zona);
					const diseaseName = DISEASE_NAMES_BY_ID[newCase.id_enfermedad] || 'Caso Tropical';

					if (zone) {
						showRealTimeToast(diseaseName, zone.nombre, zone.latitud || 0, zone.longitud || 0);
					}

					await refreshMapData();
				}
			)
			.subscribe();
	});

	onDestroy(() => {
		if (realTimeChannel) {
			supabase.removeChannel(realTimeChannel);
		}
		if (map) {
			map.remove();
			map = null;
		}
	});

	function showRealTimeToast(enfermedad: string, zonaNombre: string, lat: number, lng: number) {
		activeToast = {
			show: true,
			enfermedad,
			zona: zonaNombre,
			latitud: lat,
			longitud: lng
		};
	}

	function focusOnToast() {
		if (!map || !activeToast.show) return;
		map.flyTo([activeToast.latitud, activeToast.longitud], 14, { animate: true, duration: 1.5 });
		activeToast.show = false;
	}

	async function refreshMapData() {
		const [alertsRes, tasasRes, resumenRes] = await Promise.all([
			supabase.from('v_alertas_activas').select('*'),
			supabase.from('v_tasa_incidencia').select('*'),
			supabase.from('v_resumen_zonas').select('*')
		]);

		alerts = (alertsRes.data ?? []) as unknown as AlertaActiva[];
		tasas = (tasasRes.data ?? []) as unknown as TasaIncidencia[];
		resumenZonas = resumenRes.data ?? [];

		// Re-render map layers
		if (showDistricts && districtLayer) renderDistricts();
		renderMarkers();
		if (showHeatmap) renderHeatmap();
	}

	async function tick() {
		return new Promise((r) => setTimeout(r, 200));
	}

	function getTasaForDistrito(distritoId: number): TasaIncidencia | undefined {
		const zona = zones.find((z) => z.dm_id === distritoId);
		if (!zona) return undefined;
		return tasas.find((t) => t.id_zona === zona.id_zona);
	}

	function getDistritoFillColor(distritoId: number): string {
		const tasa = getTasaForDistrito(distritoId);
		if (!tasa) return '#64748b';
		return DISTRICT_COLORS[tasa.clasificacion] ?? '#64748b';
	}

	async function initMap() {
		if (!mapContainer) return;

		const Leaflet = await import('leaflet');
		L = Leaflet.default || Leaflet;
		if (typeof window !== 'undefined') {
			(window as any).L = L;
		}
		await import('leaflet/dist/leaflet.css') as any;
		try { await import('leaflet.heat'); } catch (e) { console.warn('leaflet.heat not loaded:', e); }

		const urlParams = new URLSearchParams(window.location.search);
		const latParam = urlParams.get('lat');
		const lngParam = urlParams.get('lng');
		const zonaIdParam = urlParams.get('zonaId');

		let initialLat = -17.7833;
		let initialLng = -63.1821;
		let initialZoom = 12;

		if (latParam && lngParam) {
			const lat = parseFloat(latParam);
			const lng = parseFloat(lngParam);
			if (!isNaN(lat) && !isNaN(lng)) {
				initialLat = lat;
				initialLng = lng;
				initialZoom = 15;
			}
		}

		map = L.map(mapContainer).setView([initialLat, initialLng], initialZoom);

		if (zonaIdParam) {
			const zId = parseInt(zonaIdParam);
			const matchedZone = zones.find((z) => z.id_zona === zId);
			if (matchedZone) {
				selectedZone = matchedZone;
			}
		}

		L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
			attribution: '&copy; OpenStreetMap contributors',
			maxZoom: 18
		}).addTo(map);

		if (distritosGeo && showDistricts) {
			renderDistricts();
		}

		renderMarkers();

		setTimeout(() => map.invalidateSize(), 100);
	}

	function renderHeatmap() {
		if (!L || !map) return;
		if (heatLayer) { map.removeLayer(heatLayer); heatLayer = null; }

		const points: [number, number, number][] = [];
		resumenZonas.forEach((r: any) => {
			if (filtroEnfermedad && r.enfermedad !== filtroEnfermedad) return;
			const zone = zones.find(z => z.id_zona === r.id_zona);
			if (!zone?.latitud || !zone?.longitud) return;
			for (let i = 0; i < (r.confirmados ?? 1); i++) {
				const jitterLat = (Math.random() - 0.5) * 0.008;
				const jitterLng = (Math.random() - 0.5) * 0.008;
				points.push([zone.latitud + jitterLat, zone.longitud + jitterLng, 0.6]);
			}
		});

		if (points.length > 0 && (L as any).heatLayer) {
			heatLayer = (L as any).heatLayer(points, {
				radius: 22, blur: 18, maxZoom: 17, minOpacity: 0.35,
				gradient: {0.2: '#3b82f6', 0.4: '#22d3ee', 0.6: '#22c55e', 0.8: '#eab308', 1.0: '#ef4444'}
			}).addTo(map);
		}
	}

	function renderCentros() {
		if (!L || !map) return;
		if (centrosLayer) { map.removeLayer(centrosLayer); centrosLayer = null; }

		centrosLayer = L.layerGroup();
		const centroIcon = L.divIcon({
			html: '<div style="font-size:18px;">🏥</div>',
			iconSize: [24, 24], iconAnchor: [12, 12], className: ''
		});

		centros.forEach((c) => {
			let lat = c.latitud;
			let lng = c.longitud;

			if (!lat || !lng) {
				const zone = zones.find((z) => z.id_zona === c.id_zona);
				if (!zone?.latitud || !zone?.longitud) return;
				const jLat = (Math.random() - 0.5) * 0.003;
				const jLng = (Math.random() - 0.5) * 0.003;
				lat = zone.latitud + jLat;
				lng = zone.longitud + jLng;
			}

			const marker = L.marker([lat, lng], { icon: centroIcon });
			marker.bindPopup(`<div style="font-family:sans-serif;min-width:160px;"><h4 style="margin:0 0 .3rem;color:#1e293b;">${c.nombre}</h4><p style="margin:0;color:#64748b;font-size:.8rem;">${c.tipo ?? 'Centro'} | ${c.direccion ?? ''}</p>${c.telefono ? `<p style="margin:.2rem 0 0;color:#38bdf8;font-size:.8rem;">📞 ${c.telefono}</p>` : ''}</div>`);
			marker.addTo(centrosLayer);
		});
		centrosLayer.addTo(map);
	}

	function applyFilter() {
		renderMarkers();
		if (showHeatmap) renderHeatmap();
	}

	function renderDistricts() {
		if (!L || !distritosGeo || !map) return;

		if (districtLayer) {
			map.removeLayer(districtLayer);
		}

		try {
			districtLayer = L.geoJSON(distritosGeo, {
				style: (feature: any) => {
					const distritoId = feature.properties?.dm_id ?? feature.properties?.id;
					const fillColor = getDistritoFillColor(distritoId);
					return {
						fillColor,
						fillOpacity: 0.35,
						color: '#334155',
						weight: 2,
						opacity: 0.9
					};
				},
				onEachFeature: (feature: any, layer: any) => {
					const distritoId = feature.properties?.dm_id ?? feature.properties?.id;
					const nombre = DISTRICT_NAMES[distritoId] ?? `DM ${distritoId}`;
					const ext = feature.properties?.dm_ext;
					const displayName = ext ? `${nombre} (${ext})` : nombre;
					const tasa = getTasaForDistrito(distritoId);
					const zona = zones.find((z) => z.dm_id === distritoId);

					const popupContent = `
						<div style="font-family: sans-serif; min-width: 180px;">
							<h3 style="margin: 0 0 0.5rem; color: #1e293b;">${displayName}</h3>
							${tasa ? `
								<p style="margin: 0.25rem 0; color: #64748b; font-size: 0.85rem;">
									Tasa: <strong style="color: ${DISTRICT_COLORS[tasa.clasificacion]}">${tasa.tasa_por_100k ?? 0}</strong> / 100k hab.
								</p>
								<p style="margin: 0.25rem 0; color: #64748b; font-size: 0.85rem;">
									Clasificacion: <strong style="color: ${DISTRICT_COLORS[tasa.clasificacion]}">${tasa.clasificacion}</strong>
								</p>
								<p style="margin: 0.25rem 0; color: #64748b; font-size: 0.85rem;">
									Casos confirmados: ${tasa.total_casos}
								</p>
							` : '<p style="color: #94a3b8; font-size: 0.85rem;">Sin datos de incidencia</p>'}
							${zona ? `<p style="margin: 0.25rem 0; color: #64748b; font-size: 0.85rem;">Poblacion: ${(zona.poblacion ?? 0).toLocaleString()}</p>` : ''}
						</div>
					`;

					layer.bindPopup(popupContent);
					layer.bindTooltip(displayName, { sticky: true, className: 'district-tooltip' });

					layer.on('mouseover', function (this: any) {
						this.setStyle({ weight: 3, fillOpacity: 0.5 });
					});
					layer.on('mouseout', function (this: any) {
						districtLayer.resetStyle(this);
					});
				}
			}).addTo(map);

			console.log('District layer added to map');
		} catch (e) {
			console.error('Error renderizando distritos:', e);
		}
	}

	function renderMarkers() {
		if (!L || !map) return;

		if (markerLayer) {
			map.removeLayer(markerLayer);
		}

		markerLayer = L.layerGroup();

		zones.forEach((zone) => {
			if (!zone.latitud || !zone.longitud) return;

			const zoneResumenList = resumenZonas.filter((r) => r.id_zona === zone.id_zona);
			let confirmados = 0;
			let sospechosos = 0;
			if (filtroEnfermedad) {
				const match = zoneResumenList.find((r) => r.enfermedad === filtroEnfermedad);
				if (match) {
					confirmados = match.confirmados ?? 0;
					sospechosos = match.sospechosos ?? 0;
				}
			} else {
				confirmados = zoneResumenList.reduce((sum, r) => sum + (r.confirmados ?? 0), 0);
				sospechosos = zoneResumenList.reduce((sum, r) => sum + (r.sospechosos ?? 0), 0);
			}

			// Determine marker color based on case count
			let color = '#64748b';
			if (confirmados > 30) color = '#ef4444';
			else if (confirmados > 15) color = '#f97316';
			else if (confirmados > 5) color = '#eab308';
			else if (confirmados > 0) color = '#22c55e';

			const zoneAlert = alerts.find((a) => a.id_zona === zone.id_zona);
			if (!filtroEnfermedad && zoneAlert) {
				color = ALERT_COLORS[zoneAlert.nivel] ?? color;
			}

			const radius = 8 + Math.min(confirmados * 1.2, 22);

			const circle = L.circleMarker([zone.latitud, zone.longitud], {
				radius,
				fillColor: color,
				color: '#fff',
				weight: 2,
				opacity: 1,
				fillOpacity: 0.75
			});

			let diseaseBreakdown = '';
			if (filtroEnfermedad) {
				diseaseBreakdown = `
					<div style="margin-top: 0.5rem; padding: 0.5rem; background: rgba(56,189,248,0.1); border-radius: 4px;">
						<strong style="color: #38bdf8;">${filtroEnfermedad}</strong><br/>
						<span style="font-size: 0.8rem;">Confirmados: <strong>${confirmados}</strong></span><br/>
						<span style="font-size: 0.8rem;">Sospechosos: <strong>${sospechosos}</strong></span>
					</div>
				`;
			} else {
				diseaseBreakdown = `
					<div style="margin-top: 0.5rem; max-height: 120px; overflow-y: auto;">
						<table style="width: 100%; font-size: 0.8rem; border-collapse: collapse;">
							<thead>
								<tr style="border-bottom: 1px solid #e2e8f0; text-align: left; color: #64748b;">
									<th>Enfermedad</th>
									<th>Conf.</th>
									<th>Sosp.</th>
								</tr>
							</thead>
							<tbody>
								${zoneResumenList.map(r => `
									<tr style="border-bottom: 1px dashed #f1f5f9;">
										<td><strong>${r.enfermedad}</strong></td>
										<td>${r.confirmados}</td>
										<td>${r.sospechosos}</td>
									</tr>
								`).join('') || '<tr><td colspan="3" style="color: #94a3b8; text-align: center;">Sin casos</td></tr>'}
							</tbody>
						</table>
					</div>
				`;
			}

			const popupContent = `
				<div style="font-family: sans-serif; min-width: 220px; color: #1e293b;">
					<h3 style="margin: 0 0 0.25rem; color: #0f172a; font-size: 1rem;">${zone.nombre}</h3>
					<p style="margin: 0 0 0.5rem; color: #64748b; font-size: 0.8rem;">
						Distrito ${DISTRICT_NAMES[zone.dm_id ?? 0] ?? `DM ${zone.dm_id}`} | ${zone.municipio}
					</p>
					${diseaseBreakdown}
					${zoneAlert ? `
						<div style="margin-top: 0.5rem; padding: 0.5rem; background: ${ALERT_COLORS[zoneAlert.nivel]}22; border-radius: 4px; border-left: 3px solid ${ALERT_COLORS[zoneAlert.nivel]};">
							<strong style="color: ${ALERT_COLORS[zoneAlert.nivel]}; font-size: 0.8rem;">Alerta ${zoneAlert.nivel.toUpperCase()}</strong><br/>
							<small style="font-size: 0.75rem;">${zoneAlert.tipo}: ${zoneAlert.mensaje ?? ''}</small>
						</div>
					` : ''}
				</div>
			`;

			circle.bindPopup(popupContent);
			circle.on('click', () => {
				selectedZone = zone;
			});

			circle.addTo(markerLayer);

			// Auto open popup if it matches the redirected zoneId
			const urlParams = new URLSearchParams(window.location.search);
			const zonaIdParam = urlParams.get('zonaId');
			if (zonaIdParam && zone.id_zona === parseInt(zonaIdParam)) {
				circle.openPopup();
			}
		});

		markerLayer.addTo(map);
	}

	function toggleDistricts() {
		showDistricts = !showDistricts;
		if (!map) return;
		if (showDistricts) { renderDistricts(); }
		else if (districtLayer) { map.removeLayer(districtLayer); districtLayer = null; }
	}

	function toggleMarkers() {
		showMarkers = !showMarkers;
		if (!map) return;
		if (showMarkers) { renderMarkers(); }
		else if (markerLayer) { map.removeLayer(markerLayer); markerLayer = null; }
	}

	function toggleHeatmap() {
		showHeatmap = !showHeatmap;
		if (!map) return;
		if (showHeatmap) { renderHeatmap(); }
		else if (heatLayer) { map.removeLayer(heatLayer); heatLayer = null; }
	}

	function toggleCentros() {
		showCentros = !showCentros;
		if (!map) return;
		if (showCentros) { renderCentros(); }
		else if (centrosLayer) { map.removeLayer(centrosLayer); centrosLayer = null; }
	}
</script>

<svelte:head>
	<title>Mapa de Riesgo - SaludSCZ</title>
	<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
	<style>
		.district-tooltip {
			background: rgba(15, 23, 42, 0.9) !important;
			color: #f1f5f9 !important;
			border: none !important;
			border-radius: 6px !important;
			padding: 6px 12px !important;
			font-size: 0.85rem !important;
			font-weight: 500 !important;
			box-shadow: 0 4px 12px rgba(0,0,0,0.3) !important;
		}
		.district-tooltip::before {
			border-top-color: rgba(15, 23, 42, 0.9) !important;
		}
	</style>
</svelte:head>

<h1>Mapa de Riesgo Epidemiologico</h1>
<p style="color: var(--color-text-muted); margin-bottom: 1rem;">
	Visualizacion georreferenciada de casos por distrito y zona de Santa Cruz de la Sierra
</p>

<div class="map-controls">
	<div class="legend">
		<span class="legend-title">Nivel de alerta:</span>
		<span class="legend-item"><span class="legend-dot" style="background: #22c55e;"></span> Verde</span>
		<span class="legend-item"><span class="legend-dot" style="background: #eab308;"></span> Amarillo</span>
		<span class="legend-item"><span class="legend-dot" style="background: #f97316;"></span> Naranja</span>
		<span class="legend-item"><span class="legend-dot" style="background: #ef4444;"></span> Rojo</span>
		<span class="legend-item"><span class="legend-dot" style="background: #64748b;"></span> Sin alerta</span>
	</div>
	<div class="filter-row">
		<select class="filter-select" bind:value={filtroEnfermedad} onchange={applyFilter}>
			<option value="">Todas las enfermedades</option>
			{#each enfermedades as enf}
				<option value={enf}>{enf}</option>
			{/each}
		</select>
	</div>
	<div class="layer-toggles">
		<label class="toggle-label">
			<input type="checkbox" checked={showDistricts} onchange={toggleDistricts} />
			Distritos
		</label>
		<label class="toggle-label">
			<input type="checkbox" checked={showMarkers} onchange={toggleMarkers} />
			Zonas
		</label>
		<label class="toggle-label toggle-heat">
			<input type="checkbox" checked={showHeatmap} onchange={toggleHeatmap} />
			🔥 Mapa de calor
		</label>
		<label class="toggle-label toggle-centros">
			<input type="checkbox" checked={showCentros} onchange={toggleCentros} />
			🏥 Centros de Salud
		</label>
	</div>
</div>

{#if loading}
	<div class="loading">Cargando mapa...</div>
{:else}
	<div class="map-wrapper">
		<div bind:this={mapContainer} class="map-container"></div>
			{#if selectedZone}
				{@const zoneTasa = tasas.find((t) => t.id_zona === selectedZone?.id_zona)}
				<div class="zone-sidebar">
					<h3>{selectedZone.nombre}</h3>
					<p>Distrito {DISTRICT_NAMES[selectedZone.dm_id ?? 0] ?? `DM ${selectedZone.dm_id}`}</p>
					<p>{selectedZone.municipio}</p>
					{#if selectedZone.poblacion}
						<p>Poblacion: {selectedZone.poblacion.toLocaleString()}</p>
					{/if}
					{#if zoneTasa}
						<div class="tasa-info">
							<span class="tasa-label">Tasa incidencia:</span>
							<span class="tasa-value">{zoneTasa.tasa_por_100k ?? 0} / 100k</span>
							<span class="badge badge-{zoneTasa.clasificacion === 'muy_alta' ? 'rojo' : zoneTasa.clasificacion === 'alta' ? 'naranja' : zoneTasa.clasificacion === 'moderada' ? 'amarillo' : 'verde'}">
								{zoneTasa.clasificacion ?? '-'}
							</span>
						</div>
					{/if}
					<button class="btn btn-outline" onclick={() => (selectedZone = null)}>Cerrar</button>
				</div>
			{/if}

			{#if activeToast.show}
				<div class="realtime-toast">
					<div class="toast-header">
						<span class="toast-pulse"></span>
						<strong>🚨 NUEVO CASO DETECTADO</strong>
					</div>
					<div class="toast-body">
						<p>Se registró un caso de <strong style="color: var(--color-primary);">{activeToast.enfermedad}</strong> en <strong>{activeToast.zona}</strong>.</p>
					</div>
					<div class="toast-actions">
						<button class="btn btn-primary btn-sm" onclick={focusOnToast}>🔍 Enfocar</button>
						<button class="btn btn-outline btn-sm" onclick={() => activeToast.show = false}>Cerrar</button>
					</div>
				</div>
			{/if}
	</div>
{/if}

<style>
	.map-controls {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
		flex-wrap: wrap;
		gap: 1rem;
	}

	.legend {
		display: flex;
		gap: 1rem;
		flex-wrap: wrap;
		align-items: center;
	}

	.legend-title {
		font-size: 0.85rem;
		font-weight: 600;
		color: var(--color-text-muted);
	}

	.legend-item {
		display: flex;
		align-items: center;
		gap: 0.3rem;
		font-size: 0.85rem;
		color: var(--color-text-muted);
	}

	.legend-dot {
		width: 12px;
		height: 12px;
		border-radius: 50%;
		display: inline-block;
	}

	.layer-toggles {
		display: flex;
		gap: 1rem;
		flex-wrap: wrap;
	}

	.filter-row {
		display: flex;
		gap: 0.5rem;
	}

	.filter-select {
		padding: 0.4rem 0.8rem;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius);
		color: var(--color-text);
		font-size: 0.85rem;
		cursor: pointer;
		width: auto;
	}

	.toggle-heat, .toggle-centros {
		background: var(--color-surface-2);
		padding: 0.3rem 0.7rem;
		border-radius: var(--radius);
		transition: all 0.2s;
	}

	.toggle-label {
		display: flex;
		align-items: center;
		gap: 0.4rem;
		font-size: 0.85rem;
		color: var(--color-text-muted);
		cursor: pointer;
	}

	.toggle-label input {
		width: auto;
	}

	.map-wrapper {
		position: relative;
		border-radius: var(--radius);
		overflow: hidden;
		border: 1px solid var(--color-border);
		box-shadow: 0 4px 24px rgba(0, 0, 0, 0.12);
	}

	.map-container {
		height: 650px;
		width: 100%;
		background: #e2e8f0;
	}

	.zone-sidebar {
		position: absolute;
		top: 1rem;
		right: 1rem;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius);
		padding: 1rem;
		z-index: 1000;
		min-width: 220px;
		box-shadow: var(--shadow);
	}

	.zone-sidebar h3 {
		margin-bottom: 0.5rem;
	}

	.zone-sidebar p {
		color: var(--color-text-muted);
		font-size: 0.85rem;
		margin-bottom: 0.25rem;
	}

	.tasa-info {
		margin-top: 0.75rem;
		padding: 0.5rem;
		background: var(--color-surface-2);
		border-radius: var(--radius);
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	.tasa-label {
		font-size: 0.75rem;
		color: var(--color-text-muted);
		text-transform: uppercase;
	}

	.tasa-value {
		font-size: 1.1rem;
		font-weight: 700;
		color: var(--color-primary);
	}

	.zone-sidebar .btn {
		margin-top: 0.75rem;
		width: 100%;
		justify-content: center;
	}

	.realtime-toast {
		position: absolute;
		bottom: 1.5rem;
		right: 1.5rem;
		background: rgba(15, 23, 42, 0.95);
		border: 1px solid var(--color-primary);
		border-radius: var(--radius);
		padding: 1rem;
		z-index: 1001;
		width: 320px;
		box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.5);
		backdrop-filter: blur(8px);
		animation: slideIn 0.3s ease-out;
		color: var(--color-text);
	}

	@keyframes slideIn {
		from { transform: translateY(100px); opacity: 0; }
		to { transform: translateY(0); opacity: 1; }
	}

	.toast-header {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.85rem;
		color: var(--color-rojo);
		margin-bottom: 0.5rem;
		letter-spacing: 0.5px;
	}

	.toast-pulse {
		width: 8px;
		height: 8px;
		background-color: var(--color-rojo);
		border-radius: 50%;
		animation: pulse-red 1s infinite alternate;
	}

	@keyframes pulse-red {
		from { opacity: 0.4; }
		to { opacity: 1; box-shadow: 0 0 8px var(--color-rojo); }
	}

	.toast-body p {
		font-size: 0.9rem;
		line-height: 1.4;
		margin-bottom: 0.75rem;
		color: #e2e8f0;
	}

	.toast-actions {
		display: flex;
		gap: 0.5rem;
	}

	.toast-actions .btn {
		padding: 0.3rem 0.6rem;
		font-size: 0.75rem;
	}

	@media (max-width: 768px) {
		.map-container {
			height: 400px;
		}

		.map-controls {
			flex-direction: column;
			align-items: flex-start;
		}
	}
</style>
