# Estado del proyecto

> Leer al empezar cada tarea. Actualizar al terminarla (lo hace `/cierre`).

## Hecho
- Estructura inicial del repo: Rojo, Rokit, Wally, Selene, StyLua, luau-lsp, CI y configuración compartida de Claude Code.
- Scripts de ejemplo en `src/server`, `src/client` y `src/shared` para comprobar la sincronización.
- Entorno verificado de punta a punta (Rokit → Rojo 7.7.1 + plugin → Studio, VS Code con extensiones, MCP de Studio con playtest). Onboarding con sección "Problemas comunes".
- **Setup del entorno terminado** (auditoría del 2026-11-25): nombre del juego (Arena de AK-47), equipo de 3 codueños con revisión cruzada, place del equipo documentado (Team Create), hook que bloquea `git push` en `main`, hook de Selene con mensajes completos.

## En progreso (quién / rama)
| Tarea | Quién | Rama |
|---|---|---|
| Prueba del flujo del equipo (PR en draft, NO se une; se borra al terminar) | @RamiRoblox | `test/flujo-equipo` |

## Próximo
- [ ] **Empezar a desarrollar Arena de AK-47**: crear el primer sistema con `/nuevo-sistema`.
- [ ] H1P3R_10 activa Team Create y suma las cuentas de Roblox de @TachyonWasTaken y @vFrangi (completar la tabla de `docs/ONBOARDING.md` y `docs/OWNERS.md`).
- [ ] Escribir la descripción corta del juego (CLAUDE.md, README.md).
- [ ] Borrar `src/shared/Hello.luau` y los scripts de ejemplo cuando exista código real.

## Bugs conocidos
| Bug | Sistema | Prioridad | Notas |
|---|---|---|---|
| — | — | — | — |

## Última actualización
- 2026-11-25 — Prueba del flujo de punta a punta (`test/flujo-equipo`, no se une).
- 2026-11-25 — Arreglos de la auditoría del entorno (`fix/post-auditoria`).
- 2026-11-25 — Setup y verificación del entorno (`setup/entorno`).
- 2026-11-23 — Estructura inicial del proyecto (`main`).
