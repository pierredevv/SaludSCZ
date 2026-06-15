-- ============================================
-- SaludSCZ — Migracion 006: Fix vista tasa + RLS casos
-- ============================================

-- 1. Fix v_tasa_incidencia: cambiar intervalo de 1 año a 3 años
--    para que incluya los datos seed de 2024-2025

DROP VIEW IF EXISTS public.v_tasa_incidencia CASCADE;

CREATE VIEW public.v_tasa_incidencia AS
SELECT
    z.id_zona, z.nombre AS zona, z.poblacion,
    COUNT(c.id_caso) AS total_casos,
    ROUND(COUNT(c.id_caso) * 100000.0 / NULLIF(z.poblacion, 0), 2) AS tasa_por_100k,
    CASE
        WHEN COUNT(c.id_caso) * 100000.0 / NULLIF(z.poblacion, 0) >= 300 THEN 'muy_alta'
        WHEN COUNT(c.id_caso) * 100000.0 / NULLIF(z.poblacion, 0) >= 100 THEN 'alta'
        WHEN COUNT(c.id_caso) * 100000.0 / NULLIF(z.poblacion, 0) >= 30  THEN 'moderada'
        ELSE 'baja'
    END AS clasificacion
FROM public.caso c
JOIN public.paciente p ON c.id_paciente = p.id_paciente
JOIN public.zona z     ON p.id_zona = z.id_zona
WHERE c.estado = 'confirmado'
  AND c.fecha_registro >= (CURRENT_DATE - INTERVAL '3 years')
GROUP BY z.id_zona, z.nombre, z.poblacion
ORDER BY tasa_por_100k DESC;

-- 2. Fix RLS: permitir a usuarios autenticados leer casos
--    (solo existia policy para anon)

CREATE POLICY "auth_read_caso" ON public.caso
    FOR SELECT TO authenticated USING (true);
