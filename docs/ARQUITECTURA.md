# Arquitectura técnica

## Componentes

### Aplicación del estudiante
- Entrada por código de sesión.
- Registro con alias o identificador definido por el profesor.
- Pantalla de misión, salas, temporizador y progreso.
- Interacciones matemáticas y validación del servidor cuando proceda.

### Panel docente
- Crear y configurar sesión.
- Abrir/cerrar acceso e iniciar/pausar partida.
- Ver participantes y progreso.
- Consultar resultados y estadísticas.
- Exportar resultados.

### Backend
Supabase almacena sesiones, participantes, progreso, eventos de interacción y resultados. Las reglas de acceso deben impedir que un estudiante lea datos privados de otros participantes o respuestas maestras.

## Seguridad

- No incluir la clave secreta/service_role de Supabase en el navegador.
- Usar únicamente la clave publishable/anon en frontend.
- Activar Row Level Security en todas las tablas expuestas.
- Validar en servidor las acciones que afecten a puntuación, desbloqueos y resultados.
- No confiar en el temporizador o puntuación calculados únicamente en el navegador.
- Separar permisos de profesor y estudiante.
- Evitar almacenar datos personales innecesarios.

## Publicación

Cloudflare Pages conectado a este repositorio. Para una aplicación HTML/CSS/JS sin proceso de compilación, configurar el directorio de salida según la estructura final y no usar comandos de despliegue de Workers.
