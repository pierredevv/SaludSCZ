-- =========================================================================
-- SaludSCZ — Migración 011: Habilitación de Tiempo Real y Políticas de Simulación
-- Habilita la replicación en tiempo real de Supabase y concede permisos de inserción RLS
-- =========================================================================

-- 1. Habilitar la publicación en tiempo real para la tabla 'caso'
-- Esto permite que el cliente de Supabase se suscriba a eventos INSERT/UPDATE/DELETE en tiempo real.
DO $$
BEGIN
  -- Verificar si la relación ya está en la publicación para evitar duplicaciones o errores
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_publication_rel pr
    JOIN pg_class c ON c.oid = pr.prrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_publication p ON p.oid = pr.prpubid
    WHERE p.pubname = 'supabase_realtime'
      AND n.nspname = 'public'
      AND c.relname = 'caso'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.caso;
  END IF;
END $$;

-- 2. Conceder políticas RLS para inserción pública en las tablas críticas de simulación
-- Esto asegura que el simulador en vivo pueda registrar pacientes y casos de forma rápida y sin trabas de autenticación durante la feria.

-- Permisos para 'paciente'
DROP POLICY IF EXISTS "public_insert_paciente" ON public.paciente;
CREATE POLICY "public_insert_paciente" ON public.paciente 
    FOR INSERT TO public 
    WITH CHECK (true);

-- Permisos para 'caso'
DROP POLICY IF EXISTS "public_insert_caso" ON public.caso;
CREATE POLICY "public_insert_caso" ON public.caso 
    FOR INSERT TO public 
    WITH CHECK (true);

-- Permisos para 'caso_sintoma'
DROP POLICY IF EXISTS "public_insert_caso_sintoma" ON public.caso_sintoma;
CREATE POLICY "public_insert_caso_sintoma" ON public.caso_sintoma 
    FOR INSERT TO public 
    WITH CHECK (true);

-- Otorgar permisos a anon y authenticated para insertar en estas tablas
GRANT INSERT ON TABLE public.paciente TO anon, authenticated;
GRANT INSERT ON TABLE public.caso TO anon, authenticated;
GRANT INSERT ON TABLE public.caso_sintoma TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.paciente_id_paciente_seq TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.caso_id_caso_seq TO anon, authenticated;

-- 3. Sincronizar secuencias de autoincremento con los IDs ya insertados manualmente
SELECT setval(pg_get_serial_sequence('public.paciente', 'id_paciente'), COALESCE(MAX(id_paciente), 1)) FROM public.paciente;
SELECT setval(pg_get_serial_sequence('public.caso', 'id_caso'), COALESCE(MAX(id_caso), 1)) FROM public.caso;
