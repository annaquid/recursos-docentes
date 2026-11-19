-- Run this migration in the Supabase SQL Editor after deploying the updated student-game.html.
-- Migración segura de 5 a 10 salas.
-- Ejecutar UNA VEZ en Supabase > SQL Editor.
DO $migrate$
DECLARE c record;
BEGIN
  FOR c IN
    SELECT conname, conrelid::regclass AS table_name
    FROM pg_constraint
    WHERE conrelid IN ('public.room_progress'::regclass, 'public.interaction_events'::regclass)
      AND contype='c'
      AND pg_get_constraintdef(oid) ILIKE '%room_number%'
  LOOP
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', c.table_name, c.conname);
  END LOOP;
END $migrate$;

ALTER TABLE public.room_progress
  ADD CONSTRAINT room_progress_room_number_check CHECK (room_number BETWEEN 1 AND 10);

ALTER TABLE public.interaction_events
  ADD CONSTRAINT interaction_events_room_number_check CHECK (room_number BETWEEN 1 AND 10);

-- El trigger completa los registros 6..10 incluso para participantes creados
-- por la función join_game_session que originalmente insertaba solo 1..5.
CREATE OR REPLACE FUNCTION public.ensure_ten_room_progress()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=''
AS $$
BEGIN
  INSERT INTO public.room_progress(participant_id,room_number,status,score,attempts,hints_used)
  SELECT NEW.id,n,CASE WHEN n=1 THEN 'available' ELSE 'locked' END,0,0,0
  FROM generate_series(6,10) AS n
  ON CONFLICT (participant_id,room_number) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ensure_ten_room_progress ON public.participants;
CREATE TRIGGER trg_ensure_ten_room_progress
AFTER INSERT ON public.participants
FOR EACH ROW EXECUTE FUNCTION public.ensure_ten_room_progress();

-- Añadir las cinco nuevas salas a participantes que ya existían.
INSERT INTO public.room_progress(participant_id,room_number,status,score,attempts,hints_used)
SELECT p.id,n,'locked',0,0,0
FROM public.participants p
CROSS JOIN generate_series(6,10) AS n
ON CONFLICT (participant_id,room_number) DO NOTHING;

-- Se preserva el estado de progreso ya existente en las salas 1..5.

CREATE OR REPLACE FUNCTION public.submit_room_answer(
  p_participant_id uuid,
  p_token text,
  p_room_number integer,
  p_answer jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=''
AS $$
DECLARE
  v_p public.participants%ROWTYPE;
  v_s public.game_sessions%ROWTYPE;
  v_r public.room_progress%ROWTYPE;
  v_ok boolean := false;
  v_score integer := 100;
BEGIN
  SELECT * INTO v_p FROM public.participants
  WHERE id=p_participant_id
    AND access_token_hash=encode(extensions.digest(p_token,'sha256'),'hex');
  IF NOT FOUND THEN RETURN jsonb_build_object('accepted',false,'message','Acceso no válido.'); END IF;

  SELECT * INTO v_s FROM public.game_sessions WHERE id=v_p.session_id;
  IF v_s.status<>'active' THEN RETURN jsonb_build_object('accepted',false,'message','La partida no está activa.'); END IF;
  IF p_room_number NOT BETWEEN 1 AND 10 THEN RETURN jsonb_build_object('accepted',false,'message','Sala no válida.'); END IF;

  SELECT * INTO v_r FROM public.room_progress
  WHERE participant_id=p_participant_id AND room_number=p_room_number FOR UPDATE;
  IF NOT FOUND OR v_r.status='locked' THEN RETURN jsonb_build_object('accepted',false,'message','Esta sala todavía está bloqueada.'); END IF;
  IF v_r.status='completed' THEN RETURN jsonb_build_object('accepted',true,'message','Sala ya superada.','score',v_r.score); END IF;

  CASE p_room_number
    WHEN 1 THEN
      v_ok := p_answer->>'pairs'='(1,1);(1,2);(1,3);(2,1);(2,2);(3,1)'
        AND p_answer->>'matrix'='111|110|100'
        AND p_answer->>'domain'='1,2,3'
        AND p_answer->>'range'='1,2,3'
        AND p_answer->>'reflexive'='false'
        AND p_answer->>'symmetric'='true'
        AND p_answer->>'antisymmetric'='false'
        AND p_answer->>'transitive'='false'
        AND p_answer->>'equivalence'='false'
        AND p_answer->>'partial_order'='false';
    WHEN 2 THEN
      v_ok := p_answer->>'reflexive'='true'
        AND p_answer->>'symmetric'='true'
        AND p_answer->>'antisymmetric'='false'
        AND p_answer->>'transitive'='true'
        AND p_answer->>'failed_property'='antisymmetric';
    WHEN 3 THEN
      v_ok := p_answer->>'inverse_relation'='a1,b1,b2,c3'
        AND p_answer->>'composition'='1x,1y,1z,2y,2z,3y';
    WHEN 4 THEN
      v_ok := p_answer->>'divides_2_3'='false'
        AND p_answer->>'divides_2_8'='true'
        AND p_answer->>'divides_3_12'='true'
        AND p_answer->>'divides_8_12'='false'
        AND p_answer->>'divisibility_covers'='1-2,1-3,12-24,2-4,2-6,3-6,4-12,4-8,6-12,8-24'
        AND p_answer->>'div_minimal'='1'
        AND p_answer->>'div_maximal'='24'
        AND p_answer->>'div_least'='1'
        AND p_answer->>'div_greatest'='24';
    WHEN 5 THEN
      v_ok := p_answer->>'poset_minimal'='a,b'
        AND p_answer->>'poset_maximal'='d,e'
        AND p_answer->>'poset_least'='false'
        AND p_answer->>'poset_greatest'='false'
        AND p_answer->>'ab_comparable'='false'
        AND p_answer->>'poset_lower'='a,b,c'
        AND lower(p_answer->>'poset_upper')='ninguno'
        AND lower(p_answer->>'poset_inf')='c'
        AND lower(p_answer->>'poset_sup')='ninguno';
    WHEN 6 THEN
      v_ok := p_answer->>'gcd'='18'
        AND p_answer->>'quotients'='1,3,1,2'
        AND p_answer->>'remainder_sequence'='54,36,18,0';
    WHEN 7 THEN
      v_ok := p_answer->>'bezout_x'='4'
        AND p_answer->>'bezout_y'='-5'
        AND p_answer->>'dio_x'='2'
        AND p_answer->>'dio_y'='1';
    WHEN 8 THEN
      v_ok := p_answer->>'remainder'='7'
        AND p_answer->>'inverse'='4'
        AND p_answer->>'power'='4';
    WHEN 9 THEN
      v_ok := p_answer->>'representative'='7'
        AND p_answer->>'reduced_modulus'='15'
        AND p_answer->>'solutions'='7,22,37'
        AND p_answer->>'count'='3';
    WHEN 10 THEN
      v_ok := false;
  END CASE;

  UPDATE public.room_progress
  SET attempts=attempts+1,
      status=CASE WHEN v_ok THEN 'completed' ELSE 'in_progress' END,
      score=CASE WHEN v_ok THEN GREATEST(COALESCE(score,0),v_score) ELSE score END,
      completed_at=CASE WHEN v_ok THEN now() ELSE completed_at END,
      updated_at=now()
  WHERE participant_id=p_participant_id AND room_number=p_room_number;

  INSERT INTO public.interaction_events(participant_id,room_number,event_type,event_data)
  VALUES(p_participant_id,p_room_number,CASE WHEN v_ok THEN 'room_completed' ELSE 'answer_rejected' END,
    jsonb_build_object('answer',p_answer));

  IF v_ok AND p_room_number<10 THEN
    UPDATE public.room_progress SET status='available',updated_at=now()
    WHERE participant_id=p_participant_id AND room_number=p_room_number+1 AND status='locked';
  END IF;

  IF v_ok THEN
    INSERT INTO public.game_results(participant_id,total_score,completed_rooms,elapsed_seconds,finished_at,summary)
    SELECT p_participant_id,
      (SELECT COALESCE(sum(score),0) FROM public.room_progress WHERE participant_id=p_participant_id),
      (SELECT count(*) FROM public.room_progress WHERE participant_id=p_participant_id AND status='completed'),
      GREATEST(0,extract(epoch FROM(now()-COALESCE(v_s.starts_at,now())))::integer),
      CASE WHEN p_room_number=10 THEN now() ELSE NULL END,
      jsonb_build_object('last_room',p_room_number)
    ON CONFLICT(participant_id) DO UPDATE SET
      total_score=EXCLUDED.total_score,completed_rooms=EXCLUDED.completed_rooms,
      elapsed_seconds=EXCLUDED.elapsed_seconds,
      finished_at=COALESCE(EXCLUDED.finished_at,public.game_results.finished_at),
      summary=EXCLUDED.summary;
  END IF;

  RETURN jsonb_build_object('accepted',v_ok,
    'message',CASE WHEN v_ok THEN 'Mecanismo desbloqueado. La siguiente sala está disponible.' ELSE 'La respuesta no es correcta. Revisa el procedimiento e inténtalo de nuevo.' END,
    'score',CASE WHEN v_ok THEN v_score ELSE 0 END,
    'next_room',CASE WHEN v_ok AND p_room_number<10 THEN p_room_number+1 ELSE NULL END);
END;
$$;

REVOKE ALL ON FUNCTION public.submit_room_answer(uuid,text,integer,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_room_answer(uuid,text,integer,jsonb) TO anon,authenticated;
