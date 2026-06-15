export interface Zona {
	id_zona: number;
	nombre: string;
	distrito: string | null;
	municipio: string;
	latitud: number | null;
	longitud: number | null;
	poblacion: number | null;
	dm_id: number | null;
	created_at: string;
	updated_at: string;
}

export interface Enfermedad {
	id_enfermedad: number;
	nombre: string;
	tipo: 'viral' | 'bacteriana' | 'parasitaria';
	descripcion: string | null;
	vector: string | null;
	created_at: string;
	updated_at: string;
}

export interface CentroSalud {
	id_centro: number;
	nombre: string;
	tipo: 'hospital' | 'clinica' | 'centro_de_salud' | 'puesto_de_salud' | null;
	direccion: string | null;
	telefono: string | null;
	id_zona: number;
	created_at: string;
	updated_at: string;
}

export interface Usuario {
	id_usuario: number;
	nombre: string;
	email: string;
	contrasena_hash: string;
	rol: 'admin' | 'medico' | 'enfermero' | 'ciudadano';
	id_centro: number | null;
	created_at: string;
	updated_at: string;
}

export interface Paciente {
	id_paciente: number;
	nombre: string;
	apellido: string;
	fecha_nacimiento: string | null;
	sexo: 'M' | 'F' | 'O' | null;
	telefono: string | null;
	direccion: string | null;
	id_zona: number | null;
	created_at: string;
	updated_at: string;
}

export interface Caso {
	id_caso: number;
	fecha_registro: string;
	fecha_inicio_sintomas: string | null;
	estado: 'sospechoso' | 'confirmado' | 'descartado' | 'recuperado' | 'fallecido';
	confirmacion: 'clinica' | 'laboratorio' | 'epidemiologica' | null;
	id_paciente: number;
	id_enfermedad: number;
	id_centro: number;
	id_usuario: number;
	created_at: string;
	updated_at: string;
}

export interface Sintoma {
	id_sintoma: number;
	nombre: string;
	descripcion: string | null;
	nivel_gravedad: 'leve' | 'moderado' | 'grave';
	created_at: string;
	updated_at: string;
}

export interface CasoSintoma {
	id_caso: number;
	id_sintoma: number;
	fecha_aparicion: string | null;
	intensidad: 'leve' | 'moderada' | 'intensa';
	created_at: string;
}

export interface Alerta {
	id_alerta: number;
	fecha_inicio: string;
	fecha_fin: string | null;
	tipo: string;
	mensaje: string | null;
	nivel: 'verde' | 'amarillo' | 'naranja' | 'rojo';
	activa: boolean;
	id_zona: number;
	created_at: string;
	updated_at: string;
}

export interface CasoConRelaciones extends Caso {
	paciente: Paciente;
	enfermedad: Enfermedad;
	centro_salud: CentroSalud;
	usuario: Usuario;
}

export interface ResumenZona {
	id_zona: number;
	zona: string;
	distrito: string | null;
	latitud: number | null;
	longitud: number | null;
	poblacion: number | null;
	enfermedad: string;
	total_casos: number;
	confirmados: number;
	sospechosos: number;
	ultimo_caso: string | null;
}

export interface TasaIncidencia {
	id_zona: number;
	zona: string;
	poblacion: number | null;
	total_casos: number;
	tasa_por_100k: number | null;
	clasificacion: 'muy_alta' | 'alta' | 'moderada' | 'baja';
}

export interface EvolucionSemanal {
	anio: number;
	semana: number;
	fecha_semana: string;
	enfermedad: string;
	total_casos: number;
	confirmados: number;
}

export interface AlertaActiva extends Alerta {
	zona: string;
	distrito: string | null;
	latitud: number | null;
	longitud: number | null;
	casos_desde_alerta: number;
}

export const ALERT_COLORS: Record<string, string> = {
	verde: '#22c55e',
	amarillo: '#eab308',
	naranja: '#f97316',
	rojo: '#ef4444'
};

export const ALERT_LABELS: Record<string, string> = {
	verde: 'Verde - Bajo riesgo',
	amarillo: 'Amarillo - Monitoreo',
	naranja: 'Naranja - Alerta',
	rojo: 'Rojo - Emergencia'
};

export const DISEASE_COLORS: Record<string, string> = {
	Dengue: '#ef4444',
	Chikungunya: '#f97316',
	Zika: '#eab308',
	Leishmaniasis: '#8b5cf6',
	Malaria: '#3b82f6'
};
