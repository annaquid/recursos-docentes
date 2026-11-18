# Base de datos

El esquema SQL se definirá después de cerrar las entidades y reglas de acceso.

Entidades previstas:
- game_sessions: sesiones de clase.
- session_participants: participantes de una sesión.
- room_progress: progreso individual por sala.
- interaction_events: acciones y validaciones relevantes.
- game_results: puntuación y resumen final.
- teacher_profiles / roles: permisos docentes, si se requieren.

Antes de aplicar cambios en Supabase:
1. Revisar los objetos existentes.
2. Confirmar el proyecto correcto.
3. Exportar una copia de seguridad si se desea conservar cualquier dato.
4. Aplicar el script de reinicio solo después de comprobar las tablas y dependencias.
5. Activar y probar RLS con cuentas de profesor y estudiante.

No ejecutar un DROP SCHEMA ni borrar el proyecto completo como atajo.
