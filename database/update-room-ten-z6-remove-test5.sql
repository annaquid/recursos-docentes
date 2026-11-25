-- Actualización de validación para Sala 10: Z6 y cuatro pruebas.
-- Ejecutar UNA VEZ en Supabase > SQL Editor después de actualizar student-game.html.
-- No modifica progreso ni resultados de los estudiantes.
BEGIN;
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
      v_ok := regexp_replace(COALESCE(p_answer->>'class_0',''), '[{}()[:space:]]', '', 'g')='0'
        AND regexp_replace(COALESCE(p_answer->>'class_1',''), '[{}()[:space:]]', '', 'g')='1,5'
        AND regexp_replace(COALESCE(p_answer->>'class_2',''), '[{}()[:space:]]', '', 'g')='2,4'
        AND regexp_replace(COALESCE(p_answer->>'class_3',''), '[{}()[:space:]]', '', 'g')='3'
        AND regexp_replace(COALESCE(p_answer->>'quotient_z6',''), '[{}()[:space:]]', '', 'g') IN ('0,1,5,2,4,3','0,1,5,3,2,4','1,5,0,2,4,3','1,5,2,4,0,3','2,4,0,1,5,3','3,0,1,5,2,4')
        AND p_answer->>'divisor_class_count'='4'
        AND regexp_replace(COALESCE(p_answer->>'divisor_quotient',''), '[[:space:]]', '', 'g')='{{1},{2,3,5,7},{4,9},{6,8,10}}';
    WHEN 4 THEN
      v_ok := p_answer->>'divides_2_3'='false'
        AND p_answer->>'divides_2_8'='true'
        AND p_answer->>'divides_3_12'='true'
        AND p_answer->>'divides_8_12'='false'
        AND regexp_replace(COALESCE(p_answer->>'comparable_4',''), '[{}[:space:]]', '', 'g')='2,4,8,12'
        AND regexp_replace(COALESCE(p_answer->>'comparable_6',''), '[{}[:space:]]', '', 'g')='2,3,6,12'
        AND regexp_replace(COALESCE(p_answer->>'div_minimal',''), '[{}[:space:]]', '', 'g')='2,3'
        AND regexp_replace(COALESCE(p_answer->>'div_maximal',''), '[{}[:space:]]', '', 'g')='8,12'
        AND lower(p_answer->>'div_least')='ninguno'
        AND lower(p_answer->>'div_greatest')='ninguno'
        AND regexp_replace(COALESCE(p_answer->>'subset_minimal',''), '[{}[:space:]]', '', 'g')='4,6'
        AND regexp_replace(COALESCE(p_answer->>'subset_maximal',''), '[{}[:space:]]', '', 'g')='4,6'
        AND regexp_replace(COALESCE(p_answer->>'subset_lower',''), '[{}[:space:]]', '', 'g')='2'
        AND regexp_replace(COALESCE(p_answer->>'subset_upper',''), '[{}[:space:]]', '', 'g')='12'
        AND p_answer->>'subset_inf'='2'
        AND p_answer->>'subset_sup'='12';
    WHEN 5 THEN
      v_ok := p_answer->>'poset_minimal'='a,b'
        AND p_answer->>'poset_maximal'='d,e'
        AND p_answer->>'poset_least'='false'
        AND p_answer->>'poset_greatest'='false'
        AND p_answer->>'ab_comparable'='false'
        AND p_answer->>'poset_lower'='a,b,c'
        AND p_answer->>'poset_upper'='ninguno'
        AND p_answer->>'poset_inf'='c'
        AND p_answer->>'poset_sup'='ninguno';
    WHEN 6 THEN
      v_ok := regexp_replace(COALESCE(p_answer->>'quotients',''), '[[:space:]]', '', 'g')='1,3,1,2'
        AND regexp_replace(COALESCE(p_answer->>'remainder_sequence',''), '[[:space:]]', '', 'g')='54,36,18,0'
        AND p_answer->>'gcd'='18'
        AND p_answer->>'lcm'='2772'
        AND p_answer->>'bezout_x'='4'
        AND p_answer->>'bezout_y'='-5'
        AND p_answer->>'dio_x'='2'
        AND p_answer->>'dio_y'='1';
    WHEN 7 THEN
      v_ok := p_answer->>'solvable'='true'
        AND p_answer->>'reduced_a'='1'
        AND p_answer->>'reduced_b'='7'
        AND p_answer->>'reduced_modulus'='15'
        AND p_answer->>'reduced_solution'='7'
        AND regexp_replace(COALESCE(p_answer->>'solutions',''), '[[:space:]]', '', 'g')='7,22,37';
    WHEN 8 THEN
      v_ok := p_answer->>'remainder'='7'
        AND p_answer->>'power'='4'
        AND p_answer->>'inverse'='4';
    WHEN 9 THEN
      v_ok := p_answer->>'inverse_exists'='true'
        AND p_answer->>'gcd_5_18'='1'
        AND p_answer->>'inverse5'='11'
        AND p_answer->>'product'='8'
        AND p_answer->>'final_result'='16';
    WHEN 10 THEN
      v_ok := translate(COALESCE(p_answer->>'relation_pairs',''), ' {}()[]' || chr(9) || chr(10) || chr(13), '')='0,0,0,1,1,1,1,2,2,2,3,3,3,4,4,4,5,5'
        AND p_answer->>'reflexive10'='true'
        AND p_answer->>'symmetric10'='false'
        AND p_answer->>'antisymmetric10'='true'
        AND p_answer->>'transitive10'='false'
        AND translate(COALESCE(p_answer->>'added_pairs',''), ' {}()[]' || chr(9) || chr(10) || chr(13), '')='0,2'
        AND translate(COALESCE(p_answer->>'hasse_edges',''), ' {}()[]' || chr(9) || chr(10) || chr(13), '')='0,1,1,2,3,4';
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
COMMIT;
