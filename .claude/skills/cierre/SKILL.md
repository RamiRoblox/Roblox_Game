---
name: cierre
description: Cierre de una tarea. Revisa el diff, corre selene y stylua --check, actualiza PROJECT_STATE y el doc del sistema, suma a DECISIONS si se decidió algo, hace commit con mensaje descriptivo, push de la rama y ofrece abrir el PR con gh pr create. Usar al terminar una tarea.
disable-model-invocation: true
---

# /cierre — terminar una tarea

Respondé en español. Seguí estos pasos en orden y frená si algo falla:

1. **Rama**
   - `git branch --show-current`. Si es `main`, **frená**: proponé crear una rama (`git switch -c feature/<nombre>`) y mover los cambios ahí antes de seguir.

2. **Revisar los cambios**
   - `git status` y `git diff` (y `git diff --staged`).
   - Resumí qué cambió, por sistema. Señalá cosas que no deberían estar (prints de debug, archivos `.rbxl`, `sourcemap.json`, secretos, código comentado).
   - Chequeá las reglas de `CLAUDE.md`: remotes validados en el servidor, nada de `wait`/`spawn`/`delay`, `--!strict`, DataStores con `pcall`, `GetService`.

3. **Calidad**
   - `stylua src` (formatea) y después `stylua --check src`.
   - `selene src`. Si hay errores, arreglalos y volvé a correrlo. Los warnings se arreglan o se justifican.
   - Preguntá si se hizo un playtest con el MCP de Studio después del último cambio; si no, ofrecé hacerlo ahora (Play → revisar Output → Stop).

4. **Docs**
   - `docs/PROJECT_STATE.md`: mover la tarea a "Hecho" (o dejarla en "En progreso" con lo que falta), actualizar "Próximo", "Bugs conocidos" y "Última actualización" (fecha de hoy + rama).
   - `docs/systems/<Sistema>.md` de cada sistema tocado: archivos, API pública, remotes, datos, trampas y cómo testearlo.
   - `docs/ARCHITECTURE.md` si cambió un RemoteEvent, un DataStore o se agregó un sistema.
   - `docs/DECISIONS.md`: si se decidió algo (una librería, un patrón, un cambio de arquitectura), agregar una entrada arriba con fecha, decisión, por qué y alternativas descartadas.
   - Si la IA cometió el mismo error dos veces en esta tarea, proponé agregar la corrección a "Errores aprendidos" de `CLAUDE.md`.

5. **Commit**
   - `git add` solo de los archivos relevantes (no `git add -A` a ciegas).
   - Mensaje en español con formato Conventional Commits: `feat(<sistema>): ...`, `fix(<sistema>): ...`, `docs: ...`, `chore: ...`. Primera línea ≤ 72 caracteres; en el cuerpo, el porqué.
   - Mostrame el mensaje antes de commitear.

6. **Push**: `git push -u origin <rama>`. Nunca a `main`, nunca `--force`.

7. **PR**: ofrecé abrirlo con `gh pr create --base main --fill` o con título y cuerpo armados según `.github/pull_request_template.md` (qué cambia, sistema, cómo se testeó, checklist). Siempre sugerí pedir review a uno de los otros dos del equipo (`docs/OWNERS.md`; mi usuario sale de `gh api user --jq .login`), con `--reviewer` y su usuario de GitHub. Recordá que el PR no se une hasta que uno de ellos lo apruebe.

8. Resumí: rama, commit, link al PR y qué quedó pendiente.
