<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { supabase } from '$lib/supabase';
	import type { Zona, AlertaActiva, TasaIncidencia } from '$lib/types';
	import { ALERT_COLORS } from '$lib/types';

	let map = $state<any>(null);
	let zones = $state<Zona[]>([]);
	let alerts = $state<AlertaActiva[]>([]);
	let tasas = $state<TasaIncidencia[]>([]);
	let distritosGeo = $state<any>(null);
	let loading = $state(true);
	let selectedZone = $state<Zona | null>(null);
	let mapContainer = $state<HTMLDivElement | null>(null);
	let L: any = null;
	let districtLayer = $state<any>(null);
	let markerLayer = $state<any>(null);
	let showDistricts = $state(true);
	let showMarkers = $state(true);

	const DISTRICT_COLORS: Record<string, string> = {
		muy_alta: '#ef4444',
		alta: '#f97316',
		moderada: '#eab308',
		baja: '#22c55e'
	};

	const DISTRICT_NAMES: Record<number, string> = {
		1: 'Piraí',
		2: 'Norte Interno',
		3: 'Estación Argentina',
		4: 'El Pari',
		5: 'Norte',
		6: 'Pampa de la Isla',
		7: 'Villa Primero de Mayo',
		8: 'Ciudadela Andrés Ibáñez',
		9: 'Palmasola/Sur',
		10: 'Bajío del Oriente',
		11: 'Centro',
		12: 'Nuevo Palmar',
		13: 'El Palmar',
		14: 'Paurito',
		15: 'Montero Hoyos',
		16: 'Distrito Industrial'
	};

	onMount(async () => {
		const [zonesRes, alertsRes, tasasRes, geoRes] = await Promise.all([
			supabase.from('zona').select('*'),
			supabase.from('v_alertas_activas').select('*'),
			supabase.from('v_tasa_incidencia').select('*'),
			fetch('/geojson/distritos.geojson')
		]);

		zones = zonesRes.data ?? [];
		alerts = (alertsRes.data ?? []) as unknown as AlertaActiva[];
		tasas = (tasasRes.data ?? []) as unknown as TasaIncidencia[];

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
	});

	onDestroy(() => {
		if (map) {
			map.remove();
			map = null;
		}
	});

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

		L = await import('leaflet');
		await import('leaflet/dist/leaflet.css') as any;

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

			const zoneAlert = alerts.find((a) => a.id_zona === zone.id_zona);
			const color = zoneAlert ? ALERT_COLORS[zoneAlert.nivel] : '#64748b';
			const radius = zoneAlert ? 15 + (zoneAlert.casos_desde_alerta ?? 0) * 0.5 : 8;

			const circle = L.circleMarker([zone.latitud, zone.longitud], {
				radius,
				fillColor: color,
				color: '#fff',
				weight: 2,
				opacity: 1,
				fillOpacity: 0.7
			});

			const popupContent = `
				<div style="font-family: sans-serif; min-width: 200px;">
					<h3 style="margin: 0 0 0.5rem; color: #1e293b;">${zone.nombre}</h3>
				<p style="margin: 0; color: #64748b; font-size: 0.85rem;">
					Distrito ${DISTRICT_NAMES[zone.dm_id ?? 0] ?? `DM ${zone.dm_id}`} | ${zone.municipio}
				</p>
					${zoneAlert ? `
						<div style="margin-top: 0.5rem; padding: 0.5rem; background: ${color}22; border-radius: 4px; border-left: 3px solid ${color};">
							<strong style="color: ${color};">Alerta ${zoneAlert.nivel.toUpperCase()}</strong><br/>
							<small>${zoneAlert.tipo}: ${zoneAlert.mensaje ?? ''}</small>
						</div>
					` : '<p style="margin-top: 0.5rem; color: #22c55e;">Sin alertas activas</p>'}
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
		if (showDistricts) {
			renderDistricts();
		} else if (districtLayer) {
			map.removeLayer(districtLayer);
			districtLayer = null;
		}
	}

	function toggleMarkers() {
		showMarkers = !showMarkers;
		if (!map) return;
		if (showMarkers) {
			renderMarkers();
		} else if (markerLayer) {
			map.removeLayer(markerLayer);
			markerLayer = null;
		}
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
	<div class="layer-toggles">
		<label class="toggle-label">
			<input type="checkbox" checked={showDistricts} onchange={toggleDistricts} />
			Distritos
		</label>
		<label class="toggle-label">
			<input type="checkbox" checked={showMarkers} onchange={toggleMarkers} />
			Zonas
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
