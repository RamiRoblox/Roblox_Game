# Registro de decisiones

> Una entrada por decisión, la más nueva arriba. Corto: fecha, decisión, por qué, alternativas descartadas.

---

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
