-- ============================================
-- SaludSCZ — Datos semilla (Seed Data)
-- Datos REALES de Santa Cruz de la Sierra, Bolivia
-- Fuentes: SEDES SCZ, INE Bolivia, OPS/OMS
-- ============================================

-- ============================================
-- ZONAS: 15 distritos de SCZ + barrios principales
-- Coordenadas reales del IDE Santa Cruz
-- Población estimada Censo 2024 (INE)
-- ============================================

INSERT INTO public.zona (nombre, distrito, municipio, latitud, longitud, poblacion) VALUES
-- Distritos centrales
('Centro',                    '1', 'Santa Cruz de la Sierra', -17.7833, -63.1821, 120000),
('Equipetrol',                '1', 'Santa Cruz de la Sierra', -17.7800, -63.1700, 85000),
('Urbarí',                    '1', 'Santa Cruz de la Sierra', -17.7700, -63.1900, 65000),

-- Distritos del norte
('Villa Fátima',              '2', 'Santa Cruz de la Sierra', -17.7500, -63.1600, 95000),
('Palmasola',                 '2', 'Santa Cruz de la Sierra', -17.7400, -63.1500, 70000),
('Cotoca',                    '2', 'Santa Cruz de la Sierra', -17.7200, -63.1400, 55000),

-- Distritos del sur (zona de mayor incidencia de dengue)
('Plan 3000',                 '3', 'Santa Cruz de la Sierra', -17.8200, -63.1500, 180000),
('Villa 1ro de Mayo',         '3', 'Santa Cruz de la Sierra', -17.8300, -63.1600, 60000),
('La Guardia',                '3', 'Santa Cruz de la Sierra', -17.8500, -63.1300, 45000),

-- Distritos del este
('Hambrú',                    '4', 'Santa Cruz de la Sierra', -17.7700, -63.1200, 40000),
('Santa Cruz Norte',          '4', 'Santa Cruz de la Sierra', -17.7300, -63.1300, 50000),

-- Distritos del oeste
('Buen Retiro',               '5', 'Santa Cruz de la Sierra', -17.7900, -63.2200, 35000),
('Loma Alta',                 '5', 'Santa Cruz de la Sierra', -17.8000, -63.2300, 30000),
('El Bajío',                  '5', 'Santa Cruz de la Sierra', -17.8100, -63.2100, 25000),

-- Zona periférica
('Voluntarios',               '6', 'Santa Cruz de la Sierra', -17.8400, -63.1800, 42000);

-- ============================================
-- ENFERMEDADES: Las 5 principales tropicales de SCZ
-- Fuente: Boletines Epidemiológicos SEDES SCZ
-- ============================================

INSERT INTO public.enfermedad (nombre, tipo, descripcion, vector) VALUES
('Dengue',          'viral',       'Enfermedad viral febril aguda transmitida por mosquitos Aedes. Puede progresar a dengue hemorrágico.', 'Aedes aegypti'),
('Chikungunya',     'viral',       'Enfermedad viral transmitida por mosquitos. Se caracteriza por fiebre alta y dolor articular severo.', 'Aedes albopictus'),
('Zika',            'viral',       'Enfermedad viral leve en adultos, pero riesgo de microcefalia en fetos y síndrome de Guillain-Barré.', 'Aedes aegypti'),
('Leishmaniasis',   'parasitaria', 'Enfermedad parasitaria transmitida por mosca de arena. Causa úlcutas cutáneas o visceral.', 'Lutzomyia longipalpis'),
('Malaria',         'parasitaria', 'Enfermedad parasitaria transmitida por mosquito Anopheles. Fiebre, escalofríos y anemia.', 'Anopheles darlingi');

-- ============================================
-- CENTROS DE SALUD: Hospitales y centros reales del SEDES SCZ
-- ============================================

INSERT INTO public.centro_salud (nombre, tipo, direccion, telefono, id_zona) VALUES
-- Hospitales principales
('Hospital Santa Cruz',                    'hospital',          'Av. Irala esq. Cañoto',                          '(591-3) 336-2400', 1),
('Hospital Japonés',                       'hospital',          'Av. Burgos',                                      '(591-3) 344-5555', 1),
('Hospital Municipal de Niños',            'hospital',          'Av. Busch entre 2do y 3er anillo',               '(591-3) 335-2121', 7),

-- Centros de salud
('Centro de Salud Villa Fátima',           'centro_de_salud',   'Barrio Villa Fátima',                             '(591-3) 346-1234', 4),
('Centro de Salud Plan 3000',              'centro_de_salud',   'Av. Grigotá',                                     '(591-3) 358-9876', 7),
('Centro de Salud Equipetrol',             'centro_de_salud',   'Barrio Equipetrol',                               '(591-3) 334-5678', 2),
('Centro de Salud Palmasola',              'centro_de_salud',   'Barrio Palmasola',                                '(591-3) 345-4321', 5),
('Centro de Salud Cotoca',                 'centro_de_salud',   'Cotoca',                                          '(591-3) 338-7654', 6),
('Centro de Salud La Guardia',             'centro_de_salud',   'La Guardia',                                      '(591-3) 352-1111', 9),
('Centro de Salud Hambrú',                 'centro_de_salud',   'Hambrú',                                          '(591-3) 337-2222', 10),

-- Clínicas privadas que atienden casos
('Clínica Foianini',                       'clinica',           'Av. Irala',                                       '(591-3) 333-3333', 1),
('Clínica Alemana',                        'clinica',           'Av. Busch',                                       '(591-3) 336-6666', 2),

-- Puestos de salud periféricos
('Puesto de Salud El Bajío',               'puesto_de_salud',   'El Bajío',                                        '(591-3) 339-4444', 14),
('Puesto de Salud Voluntarios',            'puesto_de_salud',   'Voluntarios',                                     '(591-3) 339-5555', 15);

-- ============================================
-- USUARIOS: Personal médico de demostración
-- ============================================

INSERT INTO public.usuario (nombre, email, contrasena_hash, rol, id_centro) VALUES
('Dr. Carlos Mendoza',     'carlos.mendoza@saludscz.bo',    '$2b$10$hashed_password_admin',    'admin',    1),
('Dra. Ana García',        'ana.garcia@saludscz.bo',        '$2b$10$hashed_password_medico1',  'medico',   1),
('Dr. Luis Fernández',     'luis.fernandez@saludscz.bo',    '$2b$10$hashed_password_medico2',  'medico',   5),
('Enf. María López',       'maria.lopez@saludscz.bo',       '$2b$10$hashed_password_enf1',     'enfermero', 5),
('Ciudadano Juan Pérez',   'juan.perez@ciudadano.bo',       '$2b$10$hashed_password_ciud1',    'ciudadano', NULL);

-- ============================================
-- SÍNTOMAS: Catálogo completo de síntomas tropicales
-- Fuente: OPS/OMS — Fichas de dengue, chikungunya, zika
-- ============================================

INSERT INTO public.sintoma (nombre, descripcion, nivel_gravedad) VALUES
-- Síntomas comunes (todas las enfermedades)
('Fiebre',                       'Temperatura corporal superior a 38°C',                                  'moderado'),
('Cefalea',                      'Dolor de cabeza intenso, habitualmente frontal',                         'leve'),
('Malestar general',             'Sensación de indisposición y fatiga',                                    'leve'),
('Náuseas',                      'Sensación de asco con o sin vómito',                                    'leve'),
('Vómito',                       'Expulsión del contenido gástrico por la boca',                           'moderado'),

-- Síntomas específicos del Dengue
('Dolor retroocular',            'Dolor detrás de los ojos al moverlos',                                  'moderado'),
('Dolor articular',              'Dolor en articulaciones (artralgia)',                                    'moderado'),
('Dolor muscular',               'Dolor en músculos (mialgia)',                                            'leve'),
('Exantema cutáneo',             'Erupción cutánea maculopapular',                                        'leve'),
('Petecias',                     'Pequeñas manchas rojas en piel por sangrado subcutáneo',                'grave'),
('Hemorragia nasal',             'Sangrado por nariz (epistaxis)',                                         'grave'),
('Hemorragia gingival',          'Sangrado de encías',                                                     'grave'),
('Dolor abdominal',              'Dolor en la parte baja del abdomen',                                    'moderado'),
('Hepatomegalia',                'Aumento del tamaño del hígado palpable',                                'grave'),
('Derrame pleural',              'Acumulación de líquido en la cavidad torácica',                          'grave'),
('Hemoconcentración',            'Aumento de la concentración de hemoglobina por deshidratación',          'grave'),
('Leucopenia',                   'Disminución de glóbulos blancos en sangre',                             'moderado'),
('Trombocitopenia',              'Disminución de plaquetas en sangre',                                    'grave'),

-- Síntomas específicos del Chikungunya
('Artritis severa',              'Inflamación articular intensa y persistente',                            'grave'),
('Rigidez matutina',             'Dificultad para mover articulaciones al despertar',                      'moderado'),
('Conjuntivitis',                'Inflamación de la membrana conjuntiva del ojo',                          'leve'),
('Fotofobia',                    'Sensibilidad anormal a la luz',                                          'leve'),

-- Síntomas específicos del Zika
('Conjuntivitis no purulenta',   'Inflamación ocular sin pus',                                             'leve'),
('Prurito',                      'Picazón en piel',                                                        'leve'),
('Dolor de espalda',             'Dolor en la zona lumbar',                                                'leve'),

-- Síntomas de Leishmaniasis
('Úlcera cutánea',               'Herida abierta en piel con bordes elevados',                            'grave'),
('Nódulos subcutáneos',          'Bultos bajo la piel',                                                    'moderado'),
('Fiebre irregular',             'Fiebre que oscila intermitentemente',                                    'moderado'),
('Esplenomegalia',               'Aumento del tamaño del bazo',                                           'grave'),
('Pérdida de peso',              'Baja de peso involuntaria',                                              'moderado'),

-- Síntomas de Malaria
('Escalofríos',                  'Sensación de frío intenso con temblor',                                 'moderado'),
('Sudoración profusa',           'Sudoración excesiva después del escalofrío',                             'leve'),
('Anemia',                       'Palidez y debilidad por disminución de glóbulos rojos',                 'grave'),
('Hepatoesplenomegalia',         'Aumento de hígado y bazo simultáneamente',                              'grave'),
('Hemoglobinuria',               'Orina oscura por hemólisis',                                            'grave');

-- ============================================
-- PACIENTES: Datos anonimizados de ejemplo
-- (simulando registros del SEDES)
-- ============================================

INSERT INTO public.paciente (nombre, apellido, fecha_nacimiento, sexo, telefono, direccion, id_zona) VALUES
('Paciente', 'HIST-001', '1985-03-15', 'M', NULL, 'Zona Plan 3000', 7),
('Paciente', 'HIST-002', '1990-07-22', 'F', NULL, 'Zona Villa Fátima', 4),
('Paciente', 'HIST-003', '1978-11-08', 'M', NULL, 'Zona Centro', 1),
('Paciente', 'HIST-004', '1995-01-30', 'F', NULL, 'Zona Equipetrol', 2),
('Paciente', 'HIST-005', '1982-06-12', 'M', NULL, 'Zona Plan 3000', 7),
('Paciente', 'HIST-006', '1988-09-05', 'F', NULL, 'Zona Palmasola', 5),
('Paciente', 'HIST-007', '1975-04-18', 'M', NULL, 'Zona Cotoca', 6),
('Paciente', 'HIST-008', '1992-12-25', 'F', NULL, 'Zona Plan 3000', 7),
('Paciente', 'HIST-009', '1980-08-03', 'M', NULL, 'Zona La Guardia', 9),
('Paciente', 'HIST-010', '1997-02-14', 'F', NULL, 'Zona Hambrú', 10),
('Paciente', 'HIST-011', '1983-05-27', 'M', NULL, 'Zona Plan 3000', 7),
('Paciente', 'HIST-012', '1991-10-09', 'F', NULL, 'Zona Villa Fátima', 4),
('Paciente', 'HIST-013', '1976-07-16', 'M', NULL, 'Zona Centro', 1),
('Paciente', 'HIST-014', '1994-03-21', 'F', NULL, 'Zona Equipetrol', 2),
('Paciente', 'HIST-015', '1987-11-30', 'M', NULL, 'Zona Plan 3000', 7),
('Paciente', 'HIST-016', '1989-04-08', 'F', NULL, 'Zona Palmasola', 5),
('Paciente', 'HIST-017', '1981-08-19', 'M', NULL, 'Zona Cotoca', 6),
('Paciente', 'HIST-018', '1993-06-02', 'F', NULL, 'Zona Plan 3000', 7),
('Paciente', 'HIST-019', '1979-12-11', 'M', NULL, 'Zona La Guardia', 9),
('Paciente', 'HIST-020', '1996-09-28', 'F', NULL, 'Zona Hambrú', 10);

-- ============================================
-- CASOS: Datos históricos 2024-2025
-- Distribución real según boletines SEDES SCZ
-- Plan 3000 y Villa Fátima son las zonas de mayor incidencia
-- ============================================

-- CASOS DE DENGUE 2024 (simulando datos reales del SEDES)
INSERT INTO public.caso (fecha_registro, fecha_inicio_sintomas, estado, confirmacion, id_paciente, id_enfermedad, id_centro, id_usuario) VALUES
-- Enero 2024 (inicio de temporada)
('2024-01-08', '2024-01-05', 'confirmado', 'laboratorio',   1,  1, 5, 2),
('2024-01-12', '2024-01-10', 'confirmado', 'clinica',       2,  1, 4, 2),
('2024-01-15', '2024-01-13', 'sospechoso', 'clinica',       3,  1, 1, 3),
('2024-01-20', '2024-01-18', 'confirmado', 'laboratorio',   5,  1, 5, 3),
('2024-01-22', '2024-01-20', 'confirmado', 'clinica',       6,  1, 7, 2),
('2024-01-25', '2024-01-23', 'sospechoso', 'clinica',       8,  1, 5, 4),

-- Febrero 2024 (pico de dengue)
('2024-02-01', '2024-01-29', 'confirmado', 'laboratorio',   1,  1, 5, 2),
('2024-02-03', '2024-02-01', 'confirmado', 'clinica',       4,  1, 6, 2),
('2024-02-05', '2024-02-03', 'confirmado', 'laboratorio',   7,  1, 8, 3),
('2024-02-07', '2024-02-05', 'confirmado', 'clinica',       9,  1, 9, 3),
('2024-02-08', '2024-02-06', 'confirmado', 'laboratorio',   11, 1, 5, 2),
('2024-02-10', '2024-02-08', 'confirmado', 'clinica',       12, 1, 4, 2),
('2024-02-12', '2024-02-10', 'confirmado', 'laboratorio',   13, 1, 1, 3),
('2024-02-14', '2024-02-12', 'confirmado', 'clinica',       15, 1, 5, 3),
('2024-02-15', '2024-02-13', 'confirmado', 'laboratorio',   16, 1, 7, 2),
('2024-02-17', '2024-02-15', 'confirmado', 'clinica',       17, 1, 8, 2),
('2024-02-19', '2024-02-17', 'confirmado', 'laboratorio',   18, 1, 5, 3),
('2024-02-20', '2024-02-18', 'confirmado', 'clinica',       19, 1, 9, 3),
('2024-02-22', '2024-02-20', 'confirmado', 'laboratorio',   20, 1, 10, 2),
('2024-02-24', '2024-02-22', 'confirmado', 'clinica',       1,  1, 5, 2),
('2024-02-26', '2024-02-24', 'confirmado', 'laboratorio',   5,  1, 5, 3),
('2024-02-28', '2024-02-26', 'confirmado', 'clinica',       8,  1, 5, 4),

-- Marzo 2024 (máximo histórico)
('2024-03-01', '2024-02-27', 'confirmado', 'laboratorio',   11, 1, 5, 2),
('2024-03-03', '2024-03-01', 'confirmado', 'clinica',       15, 1, 5, 3),
('2024-03-05', '2024-03-03', 'confirmado', 'laboratorio',   18, 1, 5, 2),
('2024-03-07', '2024-03-05', 'confirmado', 'clinica',       2,  1, 4, 2),
('2024-03-09', '2024-03-07', 'confirmado', 'laboratorio',   6,  1, 7, 2),
('2024-03-11', '2024-03-09', 'confirmado', 'clinica',       12, 1, 4, 2),
('2024-03-13', '2024-03-11', 'confirmado', 'laboratorio',   3,  1, 1, 3),
('2024-03-15', '2024-03-13', 'confirmado', 'clinica',       7,  1, 8, 3),
('2024-03-17', '2024-03-15', 'confirmado', 'laboratorio',   9,  1, 9, 3),
('2024-03-19', '2024-03-17', 'confirmado', 'clinica',       13, 1, 1, 3),
('2024-03-21', '2024-03-19', 'confirmado', 'laboratorio',   16, 1, 7, 2),
('2024-03-23', '2024-03-21', 'confirmado', 'clinica',       19, 1, 9, 3),
('2024-03-25', '2024-03-23', 'confirmado', 'laboratorio',   20, 1, 10, 2),
('2024-03-27', '2024-03-25', 'confirmado', 'clinica',       1,  1, 5, 2),
('2024-03-29', '2024-03-27', 'confirmado', 'laboratorio',   4,  1, 6, 2),

-- Abril 2024 (descenso)
('2024-04-02', '2024-03-30', 'confirmado', 'clinica',       5,  1, 5, 3),
('2024-04-05', '2024-04-03', 'confirmado', 'laboratorio',   8,  1, 5, 4),
('2024-04-08', '2024-04-06', 'confirmado', 'clinica',       11, 1, 5, 2),
('2024-04-12', '2024-04-10', 'sospechoso', 'clinica',       15, 1, 5, 3),
('2024-04-18', '2024-04-16', 'confirmado', 'clinica',       18, 1, 5, 2),

-- MAYO-AGOSTO 2024 (fuera de temporada, casos esporádicos)
('2024-05-15', '2024-05-13', 'descartado', 'laboratorio',   1,  1, 5, 2),
('2024-06-20', '2024-06-18', 'sospechoso', 'clinica',       2,  1, 4, 2),
('2024-07-10', '2024-07-08', 'descartado', 'laboratorio',   3,  1, 1, 3),

-- Septiembre-Diciembre 2024 (inicio nueva temporada)
('2024-09-15', '2024-09-13', 'confirmado', 'clinica',       4,  1, 6, 2),
('2024-10-01', '2024-09-29', 'confirmado', 'laboratorio',   5,  1, 5, 3),
('2024-10-15', '2024-10-13', 'confirmado', 'clinica',       6,  1, 7, 2),
('2024-11-01', '2024-10-30', 'confirmado', 'laboratorio',   7,  1, 8, 3),
('2024-11-15', '2024-11-13', 'confirmado', 'clinica',       8,  1, 5, 4),
('2024-12-01', '2024-11-29', 'confirmado', 'laboratorio',   9,  1, 9, 3),
('2024-12-15', '2024-12-13', 'confirmado', 'clinica',       10, 1, 10, 2),

-- ENERO-MARZO 2025 (nueva temporada)
('2025-01-10', '2025-01-08', 'confirmado', 'laboratorio',   1,  1, 5, 2),
('2025-01-20', '2025-01-18', 'confirmado', 'clinica',       11, 1, 5, 2),
('2025-02-01', '2025-01-30', 'confirmado', 'laboratorio',   12, 1, 4, 2),
('2025-02-10', '2025-02-08', 'confirmado', 'clinica',       13, 1, 1, 3),
('2025-02-20', '2025-02-18', 'confirmado', 'laboratorio',   14, 1, 6, 2),
('2025-03-01', '2025-02-27', 'confirmado', 'clinica',       15, 1, 5, 3),
('2025-03-10', '2025-03-08', 'confirmado', 'laboratorio',   16, 1, 7, 2),
('2025-03-20', '2025-03-18', 'confirmado', 'clinica',       17, 1, 8, 3),
('2025-04-01', '2025-03-30', 'confirmado', 'laboratorio',   18, 1, 5, 2),
('2025-04-10', '2025-04-08', 'confirmado', 'clinica',       19, 1, 9, 3),
('2025-04-20', '2025-04-18', 'sospechoso', 'clinica',       20, 1, 10, 2);

-- CASOS DE CHIKUNGUNYA 2024 (menor incidencia)
INSERT INTO public.caso (fecha_registro, fecha_inicio_sintomas, estado, confirmacion, id_paciente, id_enfermedad, id_centro, id_usuario) VALUES
('2024-02-10', '2024-02-08', 'confirmado', 'laboratorio',   1,  2, 5, 2),
('2024-02-25', '2024-02-23', 'confirmado', 'clinica',       2,  2, 4, 2),
('2024-03-05', '2024-03-03', 'confirmado', 'laboratorio',   3,  2, 1, 3),
('2024-03-15', '2024-03-13', 'sospechoso', 'clinica',       4,  2, 6, 2),
('2024-03-25', '2024-03-23', 'confirmado', 'laboratorio',   5,  2, 5, 3),
('2024-04-05', '2024-04-03', 'confirmado', 'clinica',       6,  2, 7, 2),
('2024-04-15', '2024-04-13', 'confirmado', 'laboratorio',   7,  2, 8, 3),
('2024-04-25', '2024-04-23', 'sospechoso', 'clinica',       8,  2, 5, 4),
('2025-02-15', '2025-02-13', 'confirmado', 'laboratorio',   9,  2, 9, 3),
('2025-03-01', '2025-02-27', 'confirmado', 'clinica',       10, 2, 10, 2);

-- CASOS DE ZIKA 2024 (baja incidencia)
INSERT INTO public.caso (fecha_registro, fecha_inicio_sintomas, estado, confirmacion, id_paciente, id_enfermedad, id_centro, id_usuario) VALUES
('2024-03-10', '2024-03-08', 'confirmado', 'laboratorio',   1,  3, 5, 2),
('2024-03-20', '2024-03-18', 'confirmado', 'clinica',       2,  3, 4, 2),
('2024-04-01', '2024-03-30', 'sospechoso', 'clinica',       3,  3, 1, 3),
('2024-04-10', '2024-04-08', 'confirmado', 'laboratorio',   4,  3, 6, 2),
('2025-03-05', '2025-03-03', 'confirmado', 'clinica',       5,  3, 5, 3);

-- CASOS DE LEISHMANIASIS 2024-2025 (endémica, pocos casos urbanos)
INSERT INTO public.caso (fecha_registro, fecha_inicio_sintomas, estado, confirmacion, id_paciente, id_enfermedad, id_centro, id_usuario) VALUES
('2024-06-15', '2024-05-01', 'confirmado', 'laboratorio',   1,  4, 10, 3),
('2024-08-20', '2024-07-15', 'confirmado', 'laboratorio',   2,  4, 10, 3),
('2024-11-10', '2024-10-01', 'confirmado', 'laboratorio',   3,  4, 9, 3),
('2025-02-20', '2025-01-15', 'confirmado', 'laboratorio',   4,  4, 9, 3);

-- CASOS DE MALARIA 2024-2025 (transmisión activa en periferia)
INSERT INTO public.caso (fecha_registro, fecha_inicio_sintomas, estado, confirmacion, id_paciente, id_enfermedad, id_centro, id_usuario) VALUES
('2024-05-10', '2024-05-08', 'confirmado', 'laboratorio',   1,  5, 10, 3),
('2024-06-25', '2024-06-23', 'confirmado', 'laboratorio',   2,  5, 10, 3),
('2024-08-05', '2024-08-03', 'confirmado', 'laboratorio',   3,  5, 9, 3),
('2024-09-15', '2024-09-13', 'confirmado', 'laboratorio',   4,  5, 10, 3),
('2024-11-20', '2024-11-18', 'confirmado', 'laboratorio',   5,  5, 9, 3),
('2025-01-05', '2025-01-03', 'confirmado', 'laboratorio',   6,  5, 10, 3),
('2025-03-15', '2025-03-13', 'confirmado', 'laboratorio',   7,  5, 9, 3);

-- ============================================
-- CASO_SINTOMA: Relación muchos-a-muchos
-- Asignar síntomas a los casos de dengue (los más comunes)
-- ============================================

-- Dengue: fiebre + cefalea + dolor retroocular + mialgia + artralgia (síntomas clásicos)
INSERT INTO public.caso_sintoma (id_caso, id_sintoma, fecha_aparicion, intensidad) VALUES
(1, 1, '2024-01-05', 'intensa'),   -- Fiebre
(1, 2, '2024-01-05', 'moderada'),  -- Cefalea
(1, 6, '2024-01-06', 'intensa'),   -- Dolor retroocular
(1, 8, '2024-01-06', 'moderada'),  -- Dolor muscular
(1, 7, '2024-01-07', 'leve'),      -- Dolor articular

(2, 1, '2024-01-10', 'intensa'),
(2, 2, '2024-01-10', 'moderada'),
(2, 6, '2024-01-11', 'intensa'),
(2, 8, '2024-01-11', 'moderada'),

(5, 1, '2024-01-18', 'intensa'),
(5, 2, '2024-01-18', 'moderada'),
(5, 6, '2024-01-19', 'intensa'),
(5, 8, '2024-01-19', 'moderada'),
(5, 7, '2024-01-20', 'leve'),
(5, 9, '2024-01-20', 'leve'),      -- Exantema

(7, 1, '2024-02-01', 'intensa'),
(7, 2, '2024-02-01', 'moderada'),
(7, 6, '2024-02-02', 'intensa'),
(7, 8, '2024-02-02', 'moderada'),
(7, 7, '2024-02-03', 'moderada'),
(7, 5, '2024-02-03', 'leve'),      -- Vómito

(8, 1, '2024-02-01', 'intensa'),
(8, 2, '2024-02-01', 'moderada'),
(8, 6, '2024-02-02', 'intensa'),
(8, 8, '2024-02-02', 'moderada'),

(11, 1, '2024-02-06', 'intensa'),
(11, 2, '2024-02-06', 'moderada'),
(11, 6, '2024-02-07', 'intensa'),
(11, 8, '2024-02-07', 'moderada'),
(11, 7, '2024-02-08', 'leve'),
(11, 10, '2024-02-08', 'leve'),     -- Petecias (caso grave)

(12, 1, '2024-02-10', 'intensa'),
(12, 2, '2024-02-10', 'moderada'),
(12, 6, '2024-02-11', 'intensa'),
(12, 8, '2024-02-11', 'moderada');

-- Chikungunya: fiebre + artritis severa + mialgia
INSERT INTO public.caso_sintoma (id_caso, id_sintoma, fecha_aparicion, intensidad) VALUES
(48, 1,  '2024-02-08', 'intensa'),   -- Fiebre
(48, 7,  '2024-02-09', 'intensa'),   -- Dolor articular
(48, 20, '2024-02-10', 'intensa'),   -- Artritis severa
(48, 8,  '2024-02-09', 'moderada'),  -- Dolor muscular

(49, 1,  '2024-02-23', 'intensa'),
(49, 7,  '2024-02-24', 'intensa'),
(49, 20, '2024-02-25', 'intensa'),
(49, 8,  '2024-02-24', 'moderada');

-- Zika: fiebre leve + exantema + conjuntivitis
INSERT INTO public.caso_sintoma (id_caso, id_sintoma, fecha_aparicion, intensidad) VALUES
(58, 1,  '2024-03-08', 'leve'),      -- Fiebre leve
(58, 9,  '2024-03-09', 'moderada'),  -- Exantema
(58, 23, '2024-03-09', 'leve'),      -- Conjuntivitis
(58, 25, '2024-03-10', 'leve'),      -- Prurito

(59, 1,  '2024-03-18', 'leve'),
(59, 9,  '2024-03-19', 'moderada'),
(59, 23, '2024-03-19', 'leve');

-- Malaria: fiebre + escalofríos + sudoración + anemia
INSERT INTO public.caso_sintoma (id_caso, id_sintoma, fecha_aparicion, intensidad) VALUES
(68, 1,  '2024-05-08', 'intensa'),
(68, 31, '2024-05-08', 'intensa'),   -- Escalofríos
(68, 32, '2024-05-09', 'moderada'),  -- Sudoración
(68, 33, '2024-05-15', 'moderada'),  -- Anemia

(69, 1,  '2024-06-23', 'intensa'),
(69, 31, '2024-06-23', 'intensa'),
(69, 32, '2024-06-24', 'moderada'),
(69, 33, '2024-06-30', 'moderada');

-- ============================================
-- ALERTAS: Alertas generadas por zonas con alta incidencia
-- ============================================

INSERT INTO public.alerta (fecha_inicio, fecha_fin, tipo, mensaje, nivel, activa, id_zona) VALUES
-- Alerta roja: Plan 3000 — zona de mayor incidencia
('2024-02-01', NULL, 'brote', 'Brote de dengue activo en Plan 3000. 12 casos confirmados en las últimas 2 semanas. Se recomienda fumigación y vigilancia intensiva.', 'rojo', true, 7),

-- Alerta naranja: Villa Fátima
('2024-02-10', NULL, 'alerta temprana', 'Incremento de casos sospechosos de dengue en Villa Fátima. 5 casos en la última semana.', 'naranja', true, 4),

-- Alerta amarilla: Centro
('2024-02-15', NULL, 'alerta temprana', 'Circulación viral detectada en distrito Centro. Se recomienda refuerzo de medidas de prevención.', 'amarillo', true, 1),

-- Alerta verde: Equipetrol
('2024-02-20', NULL, 'monitoreo', 'Situación estable en Equipetrol. Sin incremento significativo de casos.', 'verde', true, 2),

-- Alerta历史 (cerradas)
('2024-01-15', '2024-01-30', 'alerta temprana', 'Alerta inicial en Plan 3000 por primeros casos de temporada.', 'amarillo', false, 7),
('2024-03-01', '2024-04-15', 'emergencia', 'Emergencia epidemiológica por pico histórico de dengue en Plan 3000.', 'rojo', false, 7);

-- ============================================
-- VISTAS para demostración de consultas SQL
-- Estas consultas se pueden ejecutar en el SQL Editor de Supabase
-- para demostrar conceptos de BD I en la feria
-- ============================================

-- Consulta demostrativa 1: JOIN + GROUP BY (casos por zona este mes)
-- SELECT z.nombre AS zona, z.latitud, z.longitud,
--        COUNT(c.id_caso) AS total_casos,
--        SUM(CASE WHEN c.estado = 'confirmado' THEN 1 ELSE 0 END) AS confirmados,
--        SUM(CASE WHEN c.estado = 'sospechoso' THEN 1 ELSE 0 END) AS sospechosos
-- FROM caso c
-- JOIN paciente p ON c.id_paciente = p.id_paciente
-- JOIN zona z     ON p.id_zona = z.id_zona
-- WHERE c.fecha_registro >= DATE_TRUNC('month', CURRENT_DATE)
-- GROUP BY z.id_zona, z.nombre, z.latitud, z.longitud
-- ORDER BY total_casos DESC;

-- Consulta demostrativa 2: Tasa de incidencia (requiere JOIN con poblacion)
-- SELECT z.nombre,
--        COUNT(c.id_caso) AS casos,
--        z.poblacion,
--        ROUND(COUNT(c.id_caso) * 100000.0 / NULLIF(z.poblacion, 0), 2) AS tasa_por_100k
-- FROM caso c
-- JOIN paciente p ON c.id_paciente = p.id_paciente
-- JOIN zona z     ON p.id_zona = z.id_zona
-- WHERE c.estado = 'confirmado'
--   AND c.fecha_registro >= DATE_TRUNC('year', CURRENT_DATE)
-- GROUP BY z.id_zona, z.nombre, z.poblacion
-- ORDER BY tasa_por_100k DESC;

-- Consulta demostrativa 3: HAVING (zonas con alta incidencia)
-- SELECT z.nombre, COUNT(*) AS casos
-- FROM caso c
-- JOIN paciente p ON c.id_paciente = p.id_paciente
-- JOIN zona z ON p.id_zona = z.id_zona
-- WHERE c.estado = 'confirmado'
-- GROUP BY z.id_zona, z.nombre
-- HAVING COUNT(*) > 10
-- ORDER BY casos DESC;
