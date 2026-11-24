# Registro de decisiones

> Una entrada por decisión, la más nueva arriba. Corto: fecha, decisión, por qué, alternativas descartadas.

---

### 2026-11-23 — Usamos Rojo + Git + Studio MCP
- **Decisión:** El código Luau vive en archivos (`src/`) versionados en GitHub y se sincroniza con Studio mediante Rojo. Las IAs (Claude Code) prueban los cambios con el MCP de Roblox Studio. El arte y los mapas se hacen en Studio (Team Create) y Rojo no los toca (`$ignoreUnknownInstances`). Herramientas fijadas con Rokit; paquetes con Wally; calidad con Selene + StyLua + CI.
- **Por qué:** Somos 3 personas trabajando cada una con Claude Code. Con Git las 3 IAs comparten el mismo contexto (CLAUDE.md, docs/, skills) y cada cambio pasa por una rama y un PR revisable. El MCP de Studio permite que la IA verifique en Play lo que programa.
- **Alternativas descartadas:**
  - Solo Team Create (scripts dentro de Studio): sin historial real, sin ramas ni PRs, y las IAs no comparten contexto versionado.
  - Aftman / Foreman en vez de Rokit: Rokit es el sucesor mantenido y es compatible con los dos.
