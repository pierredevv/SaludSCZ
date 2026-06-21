-- =========================================================================
-- SaludSCZ — Migración 010: Actualización Geográfica y Demográfica Oficial
-- Inserción de 16 DMs oficiales (1,848,000 habs) y 12 Establecimientos GeoJSON
-- =========================================================================

-- 1. Estructura y Limpieza en cascada de datos antiguos
ALTER TABLE public.centro_salud ADD COLUMN IF NOT EXISTS latitud DECIMAL(9, 6);
ALTER TABLE public.centro_salud ADD COLUMN IF NOT EXISTS longitud DECIMAL(9, 6);

TRUNCATE public.alerta CASCADE;
TRUNCATE public.caso_sintoma CASCADE;
TRUNCATE public.caso CASCADE;
TRUNCATE public.paciente CASCADE;
TRUNCATE public.centro_salud CASCADE;
TRUNCATE public.zona CASCADE;
TRUNCATE public.distrito_geo CASCADE;

-- 2. Inserción de los 16 Distritos Municipales oficiales con su población validada
-- Suma exacta de población: 112k+83k+85k+74k+130k+240k+245k+315k+150k+120k+60k+115k+45k+10k+35k+29k = 1,848,000 habs.
INSERT INTO public.distrito_geo (dm_id, nombre, dm_ext, poblacion) VALUES
(1,  'DM1 - Piraí', NULL, 112000),
(2,  'DM2 - Norte Interno', NULL, 83000),
(3,  'DM3 - Estación Argentina', NULL, 85000),
(4,  'DM4 - El Pari', NULL, 74000),
(5,  'DM5 - Norte', NULL, 130000),
(6,  'DM6 - Pampa de la Isla / El Dorado', NULL, 240000),
(7,  'DM7 - Villa 1ro de Mayo', NULL, 245000),
(8,  'DM8 - Plan 3000', NULL, 315000),
(9,  'DM9 - Palmasola / Sur', NULL, 150000),
(10, 'DM10 - El Bajío', NULL, 120000),
(11, 'DM11 - Centro', NULL, 60000),
(12, 'DM12 - Nuevo Palmar / El Palmar del Oratorio', NULL, 115000),
(13, 'DM U/R 13 - Distrito Urbano/Rural - El Palmar', 'El Palmar', 45000),
(14, 'DM14 - Área Urbana Paurito', 'Paurito', 35000),
(15, 'DM15 - Área Urbana Montero Hoyos', 'Montero Hoyos', 29000),
(16, 'DI - Distrito Industrial', 'Distrito Industrial', 10000);

-- 3. Inserción de Zonas correspondientes a cada Distrito Municipal en la tabla 'zona'
-- Esto permite el enlace relacional directo con las tablas de Pacientes y Centros de Salud.
-- Las coordenadas de las zonas representan los centroides estimados de los DMs dentro del BBox.
INSERT INTO public.zona (id_zona, nombre, distrito, municipio, latitud, longitud, poblacion, dm_id) OVERRIDING SYSTEM VALUE VALUES
(1,  'DM1 - Piraí', '1', 'Santa Cruz de la Sierra', -17.766444, -63.200382, 112000, 1),
(2,  'DM2 - Norte Interno', '2', 'Santa Cruz de la Sierra', -17.770604, -63.160507, 83000, 2),
(3,  'DM3 - Estación Argentina', '3', 'Santa Cruz de la Sierra', -17.792154, -63.154888, 85000, 3),
(4,  'DM4 - El Pari', '4', 'Santa Cruz de la Sierra', -17.811727, -63.195606, 74000, 4),
(5,  'DM5 - Norte', '5', 'Santa Cruz de la Sierra', -17.725832, -63.163000, 130000, 5),
(6,  'DM6 - Pampa de la Isla / El Dorado', '6', 'Santa Cruz de la Sierra', -17.755175, -63.105154, 240000, 6),
(7,  'DM7 - Villa 1ro de Mayo', '7', 'Santa Cruz de la Sierra', -17.794867, -63.105171, 245000, 7),
(8,  'DM8 - Plan 3000', '8', 'Santa Cruz de la Sierra', -17.839667, -63.112513, 315000, 8),
(9,  'DM9 - Palmasola / Sur', '9', 'Santa Cruz de la Sierra', -17.841037, -63.196035, 150000, 9),
(10, 'DM10 - El Bajío', '10', 'Santa Cruz de la Sierra', -17.824731, -63.217217, 120000, 10),
(11, 'DM11 - Centro', '11', 'Santa Cruz de la Sierra', -17.786542, -63.179256, 60000, 11),
(12, 'DM12 - Nuevo Palmar / El Palmar del Oratorio', '12', 'Santa Cruz de la Sierra', -17.880082, -63.163016, 115000, 12),
(13, 'DM U/R 13 - Distrito Urbano/Rural - El Palmar', '13', 'Santa Cruz de la Sierra', -17.875713, -63.114428, 45000, 13),
(14, 'DM14 - Área Urbana Paurito', '14', 'Santa Cruz de la Sierra', -17.885418, -62.940160, 35000, 14),
(15, 'DM15 - Área Urbana Montero Hoyos', '15', 'Santa Cruz de la Sierra', -17.645476, -62.824981, 29000, 15),
(16, 'DI - Distrito Industrial', '16', 'Santa Cruz de la Sierra', -17.740258, -63.128625, 10000, 16);

-- 4. Inserción de los 12 Establecimientos de Salud Reales definidos en el GeoJSON
-- Mapeados a la zona correspondiente (cuyo id_zona coincide con su dm_id respectivo)
INSERT INTO public.centro_salud (id_centro, nombre, tipo, direccion, telefono, id_zona, latitud, longitud) OVERRIDING SYSTEM VALUE VALUES
(1,  'INSTITUTO ONCOLOGICO DEL ORIENTE BOLIVIANO', 'hospital', 'SOBRE TERCER ANILLO INTERNO Y EXTERNO', '(591-3) 336-2400', 1, -17.762952, -63.194165),
(2,  'H. JAPONES', 'hospital', 'AV. BUSCH Y TERCER ANILLO', '(591-3) 344-5555', 2, -17.773330, -63.155020),
(3,  'HOSPITAL MATERNOLOGICO PERCY BOLAND', 'hospital', 'C/RAFAEL PEÑA CASI AV. CAÑOTO', '(591-3) 333-5555', 11, -17.778350, -63.187130),
(4,  'HOSPITAL DE NIÑOS "MARIO ORTIZ"', 'hospital', 'CALLE BUENOS AIRES', '(591-3) 333-2222', 11, -17.780710, -63.186670),
(5,  'HOSP. MUN. FRANCÉS', 'hospital', 'AV. SANTOS DUMONT 6TO ANILLO, B/PAITITI C/1 ENTRE C/MATICO Y C/1', '(591-3) 358-1111', 9, -17.854740, -63.189740),
(6,  'HOSPITAL MUNICIPAL. BAJIO DEL ORIENTE', 'hospital', 'AV. SIMON BOLIVAR CALLE ESLOVAQUIA A 2 CUADRAS DEL 6TO ANILLO.', '(591-3) 352-1111', 10, -17.832210, -63.209340),
(7,  'CAJA NACIONAL DE SALUD "EL BAJIO"', 'centro_de_salud', 'DISTRITO 10 - EL BAJIO, UV 127', '(591-3) 355-2222', 10, -17.820884, -63.222510),
(8,  'HOSITAL MUNICIPAL PLAN 3000', 'hospital', 'B/ Piraicito Av. Prefectural Diagonal Mercado Los Pocitos A 2 Cuadras De La Av. Paurito', '(591-3) 358-9876', 8, -17.839150, -63.109220),
(9,  'HOSPITAL MUNICIPAL VILLA 1RO DE MAYO', 'hospital', '7MO ANILLO ENTRE CUMAVI Y AV. 3 PASOS AL FRENTE', '(591-3) 335-2121', 7, -17.799490, -63.117940),
(10, 'CLINICA ANGEL FOIANINI', 'clinica', 'CALLE CHUQUISACA 737', '(591-3) 333-3333', 11, -17.791520, -63.180130),
(11, 'CLINICA INCOR', 'clinica', 'SOBRE CALLE ROBORE', '(591-3) 336-6666', 1, -17.788050, -63.195190),
(12, 'CLINICA LAS AMERICAS CIRUGIA PLASTICAS', 'clinica', 'B/ Aeronautico, UV 26', '(591-3) 334-5678', 4, -17.800400, -63.174900);

-- 5. Inserción de Pacientes Clínicos Simulados en los 16 DMs
-- Generamos 150 pacientes distribuidos en las zonas con peso mayor en los distritos de mayor densidad (DMs 8, 7, 6)
DO $$
DECLARE
    i INT;
    v_sexo CHAR(1);
    v_zona_id INT;
BEGIN
    FOR i IN 1..150 LOOP
        v_sexo := CASE WHEN i % 2 = 0 THEN 'M' ELSE 'F' END;
        v_zona_id := CASE 
            WHEN i % 5 = 0 THEN 8 -- DM8 - Plan 3000
            WHEN i % 5 = 1 THEN 7 -- DM7 - Villa 1ro de Mayo
            WHEN i % 5 = 2 THEN 6 -- DM6 - Pampa de la Isla
            ELSE (i % 16) + 1     -- Distribuido entre los 16 DMs
        END;
        
        INSERT INTO public.paciente (id_paciente, nombre, apellido, fecha_nacimiento, sexo, telefono, direccion, id_zona)
        VALUES (i, 'Paciente', 'REG-' || LPAD(i::text, 3, '0'), '1980-01-01'::date + (i * 100), v_sexo::public.paciente_sexo, '770' || LPAD(i::text, 5, '0'), 'Domicilio real, DM ' || v_zona_id, v_zona_id);
    END LOOP;
END $$;

-- 6. Inserción de Casos Epidemiológicos de Dengue, Chikungunya, Zika, Leishmaniasis y Malaria (2025 y 2026)
DO $$
DECLARE
    v_paciente_id INT;
    v_enfermedad_id INT;
    v_centro_id INT;
    v_estado VARCHAR(20);
    v_fecha DATE;
    v_mes INT;
    v_casos_por_dia INT;
    v_dia INT;
    v_case_counter INT := 1;
    v_usuario_id INT;
BEGIN
    -- Asegurar que exista al menos un usuario administrador
    INSERT INTO public.usuario (nombre, email, contrasena_hash, rol, id_centro)
    VALUES ('Dr. Carlos Mendoza', 'carlos.mendoza@saludscz.bo', '$2b$10$hashed_password_admin', 'admin', NULL)
    ON CONFLICT (email) DO NOTHING;

    -- Obtener el ID de un usuario existente
    SELECT id_usuario INTO v_usuario_id FROM public.usuario LIMIT 1;

    -- Generar casos para 2025
    FOR v_mes IN 1..12 LOOP
        v_casos_por_dia := CASE 
            WHEN v_mes IN (1, 2, 3, 4) THEN 4  -- Temporada de brote húmedo
            WHEN v_mes IN (5, 6, 11, 12) THEN 2
            ELSE 1
        END;

        FOR v_dia IN 1..28 BY 3 LOOP
            FOR i IN 1..v_casos_por_dia LOOP
                v_paciente_id := ((v_case_counter + i) % 150) + 1;
                v_enfermedad_id := CASE 
                    WHEN (v_case_counter + i) % 10 < 7 THEN 1 -- Dengue
                    WHEN (v_case_counter + i) % 10 = 7 THEN 2 -- Chikungunya
                    WHEN (v_case_counter + i) % 10 = 8 THEN 3 -- Zika
                    WHEN (v_case_counter + i) % 10 = 9 THEN 4 -- Leishmaniasis
                    ELSE 5 -- Malaria
                END;

                v_fecha := TO_DATE('2025-' || LPAD(v_mes::text, 2, '0') || '-' || LPAD(v_dia::text, 2, '0'), 'YYYY-MM-DD');
                v_estado := CASE WHEN (v_case_counter + i) % 10 < 8 THEN 'confirmado' ELSE 'sospechoso' END;
                -- Seleccionar uno de los 12 centros de salud de referencia
                v_centro_id := ((v_paciente_id) % 12) + 1;

                INSERT INTO public.caso (id_caso, fecha_registro, fecha_inicio_sintomas, estado, confirmacion, id_paciente, id_enfermedad, id_centro, id_usuario)
                VALUES (v_case_counter, v_fecha, v_fecha - 3, v_estado::public.caso_estado, 'laboratorio'::public.caso_confirmacion, v_paciente_id, v_enfermedad_id, v_centro_id, v_usuario_id);
                
                v_case_counter := v_case_counter + 1;
            END LOOP;
        END LOOP;
    END LOOP;

    -- Generar casos para 2026 (Primer semestre)
    FOR v_mes IN 1..6 LOOP
        v_casos_por_dia := CASE 
            WHEN v_mes IN (1, 2, 3) THEN 6  -- Incremento estacional crítico
            WHEN v_mes IN (4, 5) THEN 3
            ELSE 1
        END;

        FOR v_dia IN 1..28 BY 2 LOOP
            FOR i IN 1..v_casos_por_dia LOOP
                v_paciente_id := ((v_case_counter + i) % 150) + 1;
                v_enfermedad_id := CASE 
                    WHEN (v_case_counter + i) % 10 < 8 THEN 1 -- Más Dengue
                    WHEN (v_case_counter + i) % 10 = 8 THEN 2 -- Chikungunya
                    ELSE 3 -- Zika
                END;

                v_fecha := TO_DATE('2026-' || LPAD(v_mes::text, 2, '0') || '-' || LPAD(v_dia::text, 2, '0'), 'YYYY-MM-DD');
                v_estado := CASE WHEN (v_case_counter + i) % 10 < 9 THEN 'confirmado' ELSE 'sospechoso' END;
                v_centro_id := ((v_paciente_id) % 12) + 1;

                INSERT INTO public.caso (id_caso, fecha_registro, fecha_inicio_sintomas, estado, confirmacion, id_paciente, id_enfermedad, id_centro, id_usuario)
                VALUES (v_case_counter, v_fecha, v_fecha - 3, v_estado::public.caso_estado, 'laboratorio'::public.caso_confirmacion, v_paciente_id, v_enfermedad_id, v_centro_id, v_usuario_id);
                
                v_case_counter := v_case_counter + 1;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- 7. Insertar sintomatología para los casos activos de la bitácora
INSERT INTO public.caso_sintoma (id_caso, id_sintoma, fecha_aparicion, intensidad)
SELECT c.id_caso, s.id_sintoma, c.fecha_inicio_sintomas, 'intensa'::public.caso_sintoma_intensidad
FROM public.caso c
CROSS JOIN (SELECT id_sintoma FROM public.sintoma WHERE nombre = 'Fiebre' LIMIT 1) s
LIMIT 200;

INSERT INTO public.caso_sintoma (id_caso, id_sintoma, fecha_aparicion, intensidad)
SELECT c.id_caso, s.id_sintoma, c.fecha_inicio_sintomas, 'moderada'::public.caso_sintoma_intensidad
FROM public.caso c
CROSS JOIN (SELECT id_sintoma FROM public.sintoma WHERE nombre = 'Cefalea' LIMIT 1) s
WHERE c.id_caso % 2 = 0
LIMIT 200;

-- 8. Crear alertas activas oficiales iniciales para zonas en riesgo crítico
INSERT INTO public.alerta (fecha_inicio, tipo, mensaje, nivel, activa, id_zona) VALUES
(CURRENT_DATE - INTERVAL '5 days', 'brote', 'Brote epidemiológico confirmado de dengue en DM8 - Plan 3000.', 'rojo', true, 8),
(CURRENT_DATE - INTERVAL '3 days', 'alerta temprana', 'Incremento atípico de casos sospechosos en DM7 - Villa 1ro de Mayo.', 'naranja', true, 7),
(CURRENT_DATE - INTERVAL '1 days', 'monitoreo', 'Detección de casos importados aislados de Zika en DM1 - Piraí.', 'amarillo', true, 1);
