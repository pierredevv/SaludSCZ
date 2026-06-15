-- ============================================
-- SaludSCZ — Migración 003: Alertas Automáticas
-- Funciones SQL para generación automática de alertas
-- basadas en tasa de incidencia por zona
-- ============================================

-- ============================================
-- 1. Función: Calcular tasa de incidencia
-- ============================================

CREATE OR REPLACE FUNCTION public.fn_calcular_tasa_incidencia(
    p_id_zona BIGINT,
    p_dias INTEGER DEFAULT 30
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_total_casos BIGINT;
    v_poblacion INTEGER;
    v_tasa NUMERIC;
BEGIN
    SELECT COUNT(*) INTO v_total_casos
    FROM public.caso c
    JOIN public.paciente p ON c.id_paciente = p.id_paciente
    WHERE p.id_zona = p_id_zona
      AND c.estado = 'confirmado'
      AND c.fecha_registro >= (CURRENT_DATE - (p_dias || ' days')::INTERVAL);

    SELECT poblacion INTO v_poblacion
    FROM public.zona
    WHERE id_zona = p_id_zona;

    IF v_poblacion IS NULL OR v_poblacion = 0 THEN
        RETURN 0;
    END IF;

    v_tasa := ROUND((v_total_casos * 100000.0 / v_poblacion), 2);
    RETURN v_tasa;
END;
$$;

-- ============================================
-- 2. Función: Determinar nivel de alerta
-- ============================================

CREATE OR REPLACE FUNCTION public.fn_evaluar_nivel_alerta(
    p_tasa NUMERIC
)
RETURNS public.alerta_nivel
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
    IF p_tasa >= 300 THEN
        RETURN 'rojo';
    ELSIF p_tasa >= 100 THEN
        RETURN 'naranja';
    ELSIF p_tasa >= 30 THEN
        RETURN 'amarillo';
    ELSE
        RETURN 'verde';
    END IF;
END;
$$;

-- ============================================
-- 3. Función: Generar/cerrar alertas automáticamente
-- Evalúa todas las zonas y actualiza alertas
-- ============================================

CREATE OR REPLACE FUNCTION public.fn_generar_alertas()
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_zona RECORD;
    v_tasa NUMERIC;
    v_nivel_nuevo public.alerta_nivel;
    v_alerta_actual RECORD;
    v_mensaje TEXT;
    v_tipo TEXT;
BEGIN
    FOR v_zona IN SELECT id_zona, nombre, poblacion FROM public.zona LOOP
        -- Calcular tasa de incidencia últimos 30 días
        v_tasa := public.fn_calcular_tasa_incidencia(v_zona.id_zona, 30);
        v_nivel_nuevo := public.fn_evaluar_nivel_alerta(v_tasa);

        -- Buscar alerta activa actual de la zona
        SELECT id_alerta, nivel INTO v_alerta_actual
        FROM public.alerta
        WHERE id_zona = v_zona.id_zona
          AND activa = true
        LIMIT 1;

        -- Generar mensaje descriptivo
        v_mensaje := format(
            'Tasa de incidencia: %.1f por 100.000 hab. en últimos 30 días. Zona: %s. Población: %s.',
            v_tasa, v_zona.nombre, COALESCE(v_zona.poblacion::TEXT, 'N/D')
        );

        -- Determinar tipo de alerta
        IF v_nivel_nuevo = 'rojo' THEN
            v_tipo := 'emergencia';
        ELSIF v_nivel_nuevo = 'naranja' THEN
            v_tipo := 'brote';
        ELSIF v_nivel_nuevo = 'amarillo' THEN
            v_tipo := 'alerta temprana';
        ELSE
            v_tipo := 'monitoreo';
        END IF;

        IF v_alerta_actual IS NOT NULL THEN
            -- Ya existe alerta activa
            IF v_alerta_actual.nivel != v_nivel_nuevo THEN
                -- Nivel cambió: cerrar alerta actual y crear nueva
                UPDATE public.alerta
                SET activa = false,
                    fecha_fin = CURRENT_DATE
                WHERE id_alerta = v_alerta_actual.id_alerta;

                -- Solo crear nueva alerta si no es verde
                IF v_nivel_nuevo != 'verde' THEN
                    INSERT INTO public.alerta (fecha_inicio, tipo, mensaje, nivel, activa, id_zona)
                    VALUES (CURRENT_DATE, v_tipo, v_mensaje, v_nivel_nuevo, true, v_zona.id_zona);
                END IF;
            END IF;
            -- Si el nivel es el mismo, no hacer nada
        ELSE
            -- No hay alerta activa: crear solo si nivel >= amarillo
            IF v_nivel_nuevo IN ('amarillo', 'naranja', 'rojo') THEN
                INSERT INTO public.alerta (fecha_inicio, tipo, mensaje, nivel, activa, id_zona)
                VALUES (CURRENT_DATE, v_tipo, v_mensaje, v_nivel_nuevo, true, v_zona.id_zona);
            END IF;
        END IF;
    END LOOP;
END;
$$;

-- ============================================
-- 4. Trigger: Ejecutar evaluación al insertar caso
-- ============================================

CREATE OR REPLACE FUNCTION public.fn_trg_after_caso_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_id_zona BIGINT;
BEGIN
    -- Obtener la zona del paciente del caso nuevo
    SELECT p.id_zona INTO v_id_zona
    FROM public.paciente p
    WHERE p.id_paciente = NEW.id_paciente;

    -- Solo evaluar si el paciente tiene zona asignada
    IF v_id_zona IS NOT NULL THEN
        PERFORM public.fn_generar_alertas();
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_after_caso_insert
    AFTER INSERT ON public.caso
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_trg_after_caso_insert();

-- ============================================
-- 5. Vista: Historial de alertas (cerradas)
-- ============================================

CREATE OR REPLACE VIEW public.v_historial_alertas AS
SELECT
    a.id_alerta,
    a.fecha_inicio,
    a.fecha_fin,
    a.tipo,
    a.mensaje,
    a.nivel,
    z.nombre AS zona,
    z.distrito,
    z.poblacion,
    (a.fecha_fin - a.fecha_inicio) AS duracion_dias,
    (SELECT COUNT(*) FROM public.caso c
     JOIN public.paciente p ON c.id_paciente = p.id_paciente
     WHERE p.id_zona = z.id_zona
       AND c.fecha_registro BETWEEN a.fecha_inicio AND COALESCE(a.fecha_fin, CURRENT_DATE)
       AND c.estado = 'confirmado') AS total_casos_durante
FROM public.alerta a
JOIN public.zona z ON a.id_zona = z.id_zona
WHERE a.activa = false
ORDER BY a.fecha_fin DESC NULLS LAST;

-- ============================================
-- 6. Vista: Resumen de alertas por nivel
-- ============================================

CREATE OR REPLACE VIEW public.v_resumen_alertas AS
SELECT
    nivel,
    COUNT(*) AS total_alertas,
    COUNT(*) FILTER (WHERE activa = true) AS alertas_activas,
    COUNT(*) FILTER (WHERE activa = false) AS alertas_cerradas,
    MIN(fecha_inicio) AS primera_alerta,
    MAX(fecha_inicio) AS ultima_alerta
FROM public.alerta
GROUP BY nivel
ORDER BY
    CASE nivel
        WHEN 'rojo' THEN 1
        WHEN 'naranja' THEN 2
        WHEN 'amarillo' THEN 3
        WHEN 'verde' THEN 4
    END;
