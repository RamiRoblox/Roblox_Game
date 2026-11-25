# Registro de decisiones

> Una entrada por decisión, la más nueva arriba. Corto: fecha, decisión, por qué, alternativas descartadas.

---

### 2026-11-25 — Place del equipo en la cuenta de H1P3R_10
- **Decisión:** El place oficial de Arena de AK-47 es "Lugar de H1P3R_10" (placeId `75368429466226`), de la cuenta personal de Roblox **H1P3R_10** (@RamiRoblox). Se comparte con Team Create, y el código entra solo por Rojo desde el repo.
- **Por qué:** Ya existe y está publicado; es lo más rápido para empezar.
- **Nota:** El place está en la cuenta personal de H1P3R_10. Si más adelante queremos repartir ganancias automáticamente, hay que mudarlo a un Grupo de Roblox.
- **Alternativas descartadas:** crear un Grupo de Roblox ya (se puede hacer más adelante).

### 2026-11-25 — Tres codueños, sin dueños por sistema, con revisión cruzada
- **Decisión:** @RamiRoblox, @TachyonWasTaken y @vFrangi son cocreadores y codueños con el mismo rango. Cualquiera trabaja en cualquier sistema y cada PR lo revisa al menos uno de los otros dos.
- **Por qué:** Equipo chico y con el mismo rango; los dueños por sistema agregaban burocracia sin beneficio.
- **Alternativas descartadas:** un dueño por sistema que aprueba los PRs de ese sistema.

### 2026-11-25 — Hook que bloquea `git push` en `main`
- **Decisión:** `.claude/hooks/block-push-main.sh` (PreToolUse) bloquea cualquier `git push` que Claude intente mientras la rama actual es `main`.
- **Por qué:** Sin protección de rama (GitHub Free), los `deny` solo frenaban comandos que nombraban `main`; un `git push` a secas estando en `main` pasaba.
- **Alternativas descartadas:** `deny` de todo `git push` sin argumentos (también bloquearía el push normal de una rama).

### 2026-11-25 — VS Code usa el StyLua de Rokit
- **Decisión:** `.vscode/settings.json` tiene `stylua.searchBinaryInPATH: true`, así la extensión formatea con el StyLua fijado en `rokit.toml`.
- **Por qué:** Por defecto la extensión baja la última versión de StyLua, que puede formatear distinto que la 2.6.0 del CI y dejar el PR en rojo.
- **Alternativas descartadas:** `stylua.styluaPath` con ruta absoluta (cambia en cada máquina).

### 2026-11-23 — Repo privado sin protección de rama en GitHub
- **Decisión:** El repo es privado. La regla "nunca pushear directo a `main`" se cumple por convención (README, CLAUDE.md) y con los `deny` de `.claude/settings.json`, no con protección de rama.
- **Por qué:** GitHub Free no permite proteger ramas ni usar rulesets en repos privados (HTTP 403 al intentarlo).
- **Alternativas descartadas:** repo público (expone el código y los remotes), pagar GitHub Pro/Team (se puede reconsiderar más adelante).

### 2026-11-23 — Usamos Rojo + Git + Studio MCP
- **Decisión:** El código Luau vive en archivos (`src/`) versionados en GitHub y se sincroniza con Studio mediante Rojo. Las IAs (Claude Code) prueban los cambios con el MCP de Roblox Studio. El arte y los mapas se hacen en Studio (Team Create) y Rojo no los toca (`$ignoreUnknownInstances`). Herramientas fijadas con Rokit; paquetes con Wally; calidad con Selene + StyLua + CI.
- **Por qué:** Somos 3 personas trabajando cada una con Claude Code. Con Git las 3 IAs comparten el mismo contexto (CLAUDE.md, docs/, skills) y cada cambio pasa por una rama y un PR revisable. El MCP de Studio permite que la IA verifique en Play lo que programa.
- **Alternativas descartadas:**
  - Solo Team Create (scripts dentro de Studio): sin historial real, sin ramas ni PRs, y las IAs no comparten contexto versionado.
  - Aftman / Foreman en vez de Rokit: Rokit es el sucesor mantenido y es compatible con los dos.
