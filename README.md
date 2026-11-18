# Escape matemático · Matemática Discreta

Aplicación web para una experiencia presencial de escape room individual de 60 minutos.

## Objetivo

Cinco salas conectadas por una narrativa común:

1. Relaciones binarias.
2. Relaciones de equivalencia y de orden.
3. Divisibilidad, algoritmo de Euclides y Bézout.
4. Congruencias y aritmética modular.
5. Congruencias lineales y código final.

## Arquitectura

- **Frontend:** HTML, CSS y JavaScript.
- **Hosting:** Cloudflare Pages.
- **Backend y persistencia:** Supabase.
- **Repositorio:** GitHub.

## Estructura

- `student/`: experiencia del estudiante.
- `teacher/`: panel docente.
- `src/`: lógica compartida y módulos de las salas.
- `assets/`: imágenes, iconos y recursos.
- `database/`: esquema SQL y políticas de seguridad.
- `docs/`: decisiones de diseño y documentación.

## Estado

Proyecto en fase de diseño y preparación de la arquitectura. No desplegar como actividad evaluable hasta probar las salas, permisos y registro de resultados.

## Respaldo

El repositorio anterior `annaquid/operacion-modular` se conserva como referencia y respaldo. No modificarlo durante esta reorganización.
