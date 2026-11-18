-- Validación de las cinco salas. Ejecutar en Supabase SQL Editor.
CREATE OR REPLACE FUNCTION public.submit_room_answer(
  p_participant_id uuid,
  p_token text,
  p_room_number integer,
  p_answer jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_p public.participants%ROWTYPE;
  v_s public.game_sessions%ROWTYPE;
  v_r public.room_progress%ROWTYPE;
  v_ok boolean := false;
  v_score integer := 100;
  v_expected text;
BEGIN
  SELECT * INTO v_p
  FROM public.participants
  WHERE id = p_participant_id
    AND access_token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex');

  IF NOT FOUND THEN
    RETURN jsonb_build_object('accepted',false,'message','Acceso no válido.');
  END IF;

  SELECT * INTO v_s FROM public.game_sessions WHERE id = v_p.session_id;
  IF v_s.status <> 'active' THEN
    RETURN jsonb_build_object('accepted',false,'message','La partida no está activa.');
  END IF;

  IF p_room_number < 1 OR p_room_number > 5 THEN
    RETURN jsonb_build_object('accepted',false,'message','Sala no válida.');
  END IF;

  SELECT * INTO v_r FROM public.room_progress
  WHERE participant_id=p_participant_id AND room_number=p_room_number
  FOR UPDATE;

  IF NOT FOUND OR v_r.status='locked' THEN
    RETURN jsonb_build_object('accepted',false,'message','Esta sala todavía está bloqueada.');
  END IF;
  IF v_r.status='completed' THEN
    RETURN jsonb_build_object('accepted',true,'message','Sala ya superada.','score',v_r.score);
  END IF;

  CASE p_room_number
    WHEN 1 THEN
      v_ok := p_answer->>'reflexive'='true'
        AND p_answer->>'symmetric'='true'
        AND p_answer->>'antisymmetric'='false'
        AND p_answer->>'transitive'='true'
        AND p_answer->>'matrix'='110|110|001';
    WHEN 2 THEN
      v_ok := p_answer->>'classes'='0,3|1,4|2,5'
        AND p_answer->>'minimal'='1'
        AND p_answer->>'maximal'='12'
        AND p_answer->>'least'='1'
        AND p_answer->>'greatest'='12';
    WHEN 3 THEN
      v_ok := p_answer->>'gcd'='18'
        AND p_answer->>'x'='4'
        AND p_answer->>'y'='-5';
    WHEN 4 THEN
      v_ok := p_answer->>'remainder'='7'
        AND p_answer->>'inverse'='4';
    WHEN 5 THEN
      v_ok := p_answer->>'representative'='7'
        AND p_answer->>'solutions'='7,22,37'
        AND p_answer->>'count'='3';
  END CASE;

  UPDATE public.room_progress
  SET attempts=attempts+1,
      status=CASE WHEN v_ok THEN 'completed' ELSE 'in_progress' END,
      score=CASE WHEN v_ok THEN GREATEST(COALESCE(score,0),v_score) ELSE score END,
      completed_at=CASE WHEN v_ok THEN now() ELSE completed_at END,
      updated_at=now()
  WHERE participant_id=p_participant_id AND room_number=p_room_number;

  INSERT INTO public.interaction_events(participant_id,room_number,event_type,event_data)
  VALUES (p_participant_id,p_room_number,CASE WHEN v_ok THEN 'room_completed' ELSE 'answer_rejected' END,
          jsonb_build_object('answer',p_answer));

  IF v_ok AND p_room_number < 5 THEN
    UPDATE public.room_progress
    SET status='available', updated_at=now()
    WHERE participant_id=p_participant_id AND room_number=p_room_number+1
      AND status='locked';
  END IF;

  IF v_ok THEN
    INSERT INTO public.game_results(participant_id,total_score,completed_rooms,elapsed_seconds,finished_at,summary)
    SELECT p_participant_id,
      (SELECT COALESCE(sum(score),0) FROM public.room_progress WHERE participant_id=p_participant_id),
      (SELECT count(*) FROM public.room_progress WHERE participant_id=p_participant_id AND status='completed'),
      GREATEST(0,extract(epoch FROM (now()-COALESCE(v_s.starts_at,now())))::integer),
      CASE WHEN p_room_number=5 THEN now() ELSE NULL END,
      jsonb_build_object('last_room',p_room_number)
    ON CONFLICT (participant_id) DO UPDATE SET
      total_score=EXCLUDED.total_score,
      completed_rooms=EXCLUDED.completed_rooms,
      elapsed_seconds=EXCLUDED.elapsed_seconds,
      finished_at=COALESCE(EXCLUDED.finished_at,public.game_results.finished_at),
      summary=EXCLUDED.summary;
  END IF;

  RETURN jsonb_build_object('accepted',v_ok,
    'message',CASE WHEN v_ok THEN 'Mecanismo desbloqueado.' ELSE 'La respuesta no es correcta. Revisa el procedimiento e inténtalo de nuevo.' END,
    'score',CASE WHEN v_ok THEN v_score ELSE 0 END,
    'next_room',CASE WHEN v_ok AND p_room_number<5 THEN p_room_number+1 ELSE NULL END);
END;
$$;

REVOKE ALL ON FUNCTION public.submit_room_answer(uuid,text,integer,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_room_answer(uuid,text,integer,jsonb) TO anon, authenticated;
