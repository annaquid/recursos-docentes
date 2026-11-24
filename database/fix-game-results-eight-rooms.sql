-- Corrección urgente: permitir registrar hasta 8 salas completadas.
-- Ejecutar UNA VEZ en Supabase > SQL Editor.
-- No borra ni modifica el progreso de los participantes.

ALTER TABLE public.game_results
  DROP CONSTRAINT IF EXISTS game_results_completed_rooms_check;

ALTER TABLE public.game_results
  ADD CONSTRAINT game_results_completed_rooms_check
  CHECK (completed_rooms BETWEEN 0 AND 8);
