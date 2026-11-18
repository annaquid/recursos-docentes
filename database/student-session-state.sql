-- Estado sincronizado para la sala de espera y la partida
-- Ejecutar en Supabase > SQL Editor.
CREATE OR REPLACE FUNCTION public.get_student_session_state(
  p_participant_id uuid,
  p_token text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'participant_id', p.id,
    'alias', p.alias,
    'participant_status', p.status,
    'session_id', s.id,
    'session_title', s.title,
    'session_code', s.session_code,
    'session_status', s.status,
    'duration_seconds', s.duration_seconds,
    'starts_at', s.starts_at,
    'ends_at', s.ends_at,
    'rooms', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'room_number', rp.room_number,
          'status', rp.status,
          'score', rp.score,
          'attempts', rp.attempts,
          'hints_used', rp.hints_used
        ) ORDER BY rp.room_number
      )
      FROM public.room_progress rp
      WHERE rp.participant_id = p.id
    ), '[]'::jsonb)
  )
  INTO v_result
  FROM public.participants p
  JOIN public.game_sessions s ON s.id = p.session_id
  WHERE p.id = p_participant_id
    AND p.access_token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex');

  IF v_result IS NULL THEN
    RETURN jsonb_build_object('error', 'invalid_participant');
  END IF;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_session_state(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_student_session_state(uuid, text) TO anon, authenticated;
