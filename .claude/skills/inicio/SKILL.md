---
name: inicio
description: Arranque de una sesión de trabajo en el juego. Actualiza el repo con git pull, muestra la rama actual, lee PROJECT_STATE y ARCHITECTURE, pregunta en qué se va a trabajar, lee el doc de ese sistema y sugiere crear una rama. Usar al empezar el día o una tarea nueva.
disable-model-invocation: true
---

# /inicio — empezar a trabajar

Respondé en español. Seguí estos pasos en orden:

1. **Estado de Git**
   - `git status` → si hay cambios sin commitear, avisá y preguntá qué hacer con ellos antes de seguir (commitear en su rama, `git stash` o dejarlos). No descartes nada.
   - `git fetch` y `git pull` (en la rama actual). Si hay conflictos, frená y explicalos.
   - Mostrá en qué rama estoy. Si estoy en `main`, recordá que no se trabaja directo en `main`.

2. **Contexto del proyecto**
   - Leé `docs/PROJECT_STATE.md` y `docs/ARCHITECTURE.md` (y `docs/OWNERS.md`).
   - Resumí en pocas líneas: qué está en progreso (quién / rama), qué sigue y los bugs conocidos.

3. **Preguntá en qué voy a trabajar.** Esperá mi respuesta.

4. **Contexto del sistema**
   - Leé `docs/systems/<Sistema>.md`. Si no existe y el sistema ya tiene código, ofrecé crearlo primero a partir de `docs/systems/_TEMPLATE.md` analizando el código. Si es un sistema nuevo, sugerí `/nuevo-sistema`.
   - No hay dueños por sistema: puedo trabajar en cualquiera. Revisá si alguien más ya trabaja en eso (sección "En progreso" y `gh pr list`); si es así, avisame para coordinar antes de un cambio grande.
   - Recordame que el PR lo tiene que revisar uno de los otros dos (`docs/OWNERS.md`).

5. **Rama**
   - Sugerí un nombre: `feature/<nombre-corto>` o `fix/<nombre-corto>` (minúsculas, guiones).
   - Con mi OK: `git switch main && git pull && git switch -c <rama>`.
   - Sugerí agregar la tarea a "En progreso" de `PROJECT_STATE.md` (se commitea con el trabajo).

6. Cerrá con un plan corto de los primeros pasos y recordá: cambios chicos, playtest con el MCP de Studio después de cada cambio, y `/cierre` al terminar.
