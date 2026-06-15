-- ============================================
-- SaludSCZ — Migración 007: Corrección de RLS y Vista de Alertas
-- ============================================

-- 1. Evitar recursión infinita en políticas RLS de la tabla 'usuario'
-- Definimos una función con SECURITY DEFINER para verificar si el usuario es administrador.
-- Esto hace que la consulta se ejecute como el creador (bypasseando RLS) y evita la recursión.
CREATE OR REPLACE FUNCTION public.check_user_is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.usuario
        WHERE email = auth.jwt() ->> 'email'
          AND rol = 'admin'
    );
END;
$$;

-- Corregimos la política de la tabla 'usuario'
DROP POLICY IF EXISTS "admin_all_usuario" ON public.usuario;
CREATE POLICY "admin_all_usuario" ON public.usuario
    FOR ALL TO authenticated
    USING (public.check_user_is_admin());

-- 2. Cambiar políticas de lectura (SELECT) de 'TO anon' a 'TO public'
-- Esto permite que tanto usuarios anónimos (cerrado sesión) como autenticados (iniciado sesión)
-- puedan consultar los catálogos y datos necesarios para el dashboard, alertas y mapa.

-- Tabla 'zona'
DROP POLICY IF EXISTS "public_read_zona" ON public.zona;
CREATE POLICY "public_read_zona" ON public.zona FOR SELECT TO public USING (true);

-- Tabla 'enfermedad'
DROP POLICY IF EXISTS "public_read_enfermedad" ON public.enfermedad;
CREATE POLICY "public_read_enfermedad" ON public.enfermedad FOR SELECT TO public USING (true);

-- Tabla 'sintoma'
DROP POLICY IF EXISTS "public_read_sintoma" ON public.sintoma;
CREATE POLICY "public_read_sintoma" ON public.sintoma FOR SELECT TO public USING (true);

-- Tabla 'centro_salud'
DROP POLICY IF EXISTS "public_read_centro_salud" ON public.centro_salud;
CREATE POLICY "public_read_centro_salud" ON public.centro_salud FOR SELECT TO public USING (true);

-- Tabla 'caso'
DROP POLICY IF EXISTS "public_read_caso" ON public.caso;
CREATE POLICY "public_read_caso" ON public.caso FOR SELECT TO public USING (true);

-- Tabla 'caso_sintoma'
DROP POLICY IF EXISTS "public_read_caso_sintoma" ON public.caso_sintoma;
CREATE POLICY "public_read_caso_sintoma" ON public.caso_sintoma FOR SELECT TO public USING (true);

-- Tabla 'alerta'
DROP POLICY IF EXISTS "public_read_alerta" ON public.alerta;
CREATE POLICY "public_read_alerta" ON public.alerta FOR SELECT TO public USING (true);

-- Tabla 'distrito_geo'
DROP POLICY IF EXISTS "public_read_distrito_geo" ON public.distrito_geo;
CREATE POLICY "public_read_distrito_geo" ON public.distrito_geo FOR SELECT TO public USING (true);

-- Tabla 'paciente'
-- Se cambia a public para que los joins de estadísticas agregadas en las vistas de dashboard y tasa de incidencia
-- funcionen correctamente tanto para usuarios autenticados como para ciudadanos anónimos.
DROP POLICY IF EXISTS "public_read_paciente" ON public.paciente;
CREATE POLICY "public_read_paciente" ON public.paciente FOR SELECT TO public USING (true);


-- 3. Recrear la vista 'v_alertas_activas' para incluir la columna 'id_zona'
-- La vista original no incluía 'id_zona', lo que impedía que el frontend pudiera asociar
-- las alertas con sus zonas en el mapa interactivo.
DROP VIEW IF EXISTS public.v_alertas_activas CASCADE;

CREATE VIEW public.v_alertas_activas AS
SELECT
    a.id_alerta,
    a.id_zona, -- Columna añadida para mapeo en el frontend
    a.fecha_inicio,
    a.fecha_fin,
    a.tipo,
    a.mensaje,
    a.nivel,
    z.nombre AS zona,
    z.distrito,
    z.latitud,
    z.longitud,
    (SELECT COUNT(*) FROM public.caso c
     JOIN public.paciente p ON c.id_paciente = p.id_paciente
     WHERE p.id_zona = z.id_zona
       AND c.fecha_registro >= a.fecha_inicio
       AND c.estado = 'confirmado') AS casos_desde_alerta
FROM public.alerta a
JOIN public.zona z ON a.id_zona = z.id_zona
WHERE a.activa = true
ORDER BY
    CASE a.nivel
        WHEN 'rojo' THEN 1
        WHEN 'naranja' THEN 2
        WHEN 'amarillo' THEN 3
        WHEN 'verde' THEN 4
    END;
