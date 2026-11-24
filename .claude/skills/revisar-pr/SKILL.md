---
name: revisar-pr
description: Revisa en modo solo lectura el Pull Request de un compañero, con foco en la seguridad de los RemoteEvents (never trust the client), cambios que rompan otros sistemas y docs desactualizadas. Usar cuando hay que revisar un PR del equipo.
argument-hint: "<número de PR>"
allowed-tools: Bash(gh pr view *) Bash(gh pr diff *) Bash(gh pr checks *) Bash(gh pr list *) Bash(git log *) Bash(git diff *) Bash(git show *) Bash(git fetch *) PowerShell(gh pr view *) PowerShell(gh pr diff *) PowerShell(gh pr checks *) PowerShell(gh pr list *) PowerShell(git log *) PowerShell(git diff *) PowerShell(git show *) PowerShell(git fetch *) Read Grep Glob
---

# /revisar-pr — revisar el PR de un compañero

Respondé en español. PR: `$ARGUMENTS` (si está vacío, listá los PRs abiertos con `gh pr list` y preguntá cuál).

**Modo solo lectura:** no edites archivos, no hagas checkout de la rama, no commitees, no aprobes ni comentes en GitHub. Solo leé y reportá. Si querés publicar la review, preguntame primero y mostrame el texto.

1. **Contexto**
   - `gh pr view <n>` (descripción, autor, rama, checklist) y `gh pr checks <n>` (CI).
   - `gh pr diff <n>`.
   - Leé `CLAUDE.md`, `docs/ARCHITECTURE.md`, `docs/OWNERS.md` y el doc de cada sistema tocado (versión de `main`).

2. **Seguridad de los remotes (prioridad 1)** — por cada RemoteEvent/RemoteFunction nuevo o cambiado:
   - ¿El servidor valida tipo, `nil`, NaN/inf, rango, negativos, largo de strings/tablas?
   - ¿Valida distancia, cooldown/rate-limit y que el jugador tenga el ítem, la plata o el permiso?
   - ¿El cliente decide algo que debería decidir el servidor (precio, daño, recompensa, posición)?
   - ¿Hay `InvokeClient`? ¿`ProcessReceipt` fuera del servidor o no idempotente?
   - ¿Está en la tabla de `ARCHITECTURE.md` con su validación?

3. **Roturas en otros sistemas**
   - Cambios en APIs públicas, tipos exportados, nombres de remotes, estructura de datos guardados (¿migración para jugadores existentes?).
   - Buscá con Grep quién usa lo que cambió.
   - ¿Toca un sistema con otro dueño sin su review?

4. **Calidad Luau**: `--!strict`, tipos en la API pública, `task.*` en vez de `wait/spawn/delay`, `GetService`, DataStores con `pcall`, conexiones que se limpian.

5. **Docs**: ¿se actualizaron `PROJECT_STATE.md`, el doc del sistema, `ARCHITECTURE.md` y `DECISIONS.md` si correspondía?

6. **Reporte** con este formato:
   - **Veredicto:** ✅ aprobar / 💬 aprobar con comentarios / ❌ pedir cambios
   - **Bloqueantes** (seguridad o roturas): archivo:línea, problema, ejemplo de exploit o fallo, sugerencia.
   - **Sugerencias** (no bloqueantes).
   - **Docs faltantes.**
   - **Cómo testearlo** (pasos de playtest con el MCP de Studio).
