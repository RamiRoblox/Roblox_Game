# Estado del proyecto

> Leer al empezar cada tarea. Actualizar al terminarla (lo hace `/cierre`).

## Hecho
- Estructura inicial del repo: Rojo, Rokit, Wally, Selene, StyLua, luau-lsp, CI y configuración compartida de Claude Code.
- Scripts de ejemplo en `src/server`, `src/client` y `src/shared` para comprobar la sincronización.
- Entorno verificado de punta a punta (Rokit → Rojo 7.7.1 + plugin → Studio, VS Code con extensiones, MCP de Studio con playtest). Onboarding con sección "Problemas comunes".
- **Setup del entorno terminado** (auditoría del 2026-11-25): nombre del juego (Arena de AK-47), equipo de 3 codueños con revisión cruzada, place del equipo documentado (Team Create), hook que bloquea `git push` en `main`, hook de Selene con mensajes completos.

- **Sistema de Armas pasado a Git**: el código de disparo de la AK-47 estaba solo en Studio; ahora vive en `src/` (ver `docs/systems/Armas.md`). Probado con playtest.
- **Armas en primera persona** (`feature/viewmodel`): viewmodel con brazos, balanceo, paso, salto, retroceso de arma y cámara, apuntar con zoom, cargador de 30 validado por el servidor con recarga (R), inspección (V), pose de correr y anti-pared. Todos los valores en `ViewmodelConfig` con modo ajuste en vivo. Arreglado el control de cadencia del servidor (descartaba ~40% de los tiros) y el retroceso de cámara que dejaba la mira subiendo. Probado con playtest.

## En progreso (quién / rama)
| Tarea | Quién | Rama |
|---|---|---|
| Armas: tercera persona (Motor6D en la mano) y revisión del viewmodel | @vFrangi | `feature/viewmodel` |

## Próximo
- [ ] Armas: ponerle sonido al disparo (`fireSoundId` en `WeaponConfig`).
- [ ] Armas: tercera persona (Motor6D de `RightHand` a `Handle`, arma apuntando hacia adelante).
- [ ] Armas: contador de balas en pantalla y reserva de munición.
- [ ] Pasar `ReplicatedStorage.SkinsLegendarias` (código que vive solo en Studio) a Git.
- [ ] H1P3R_10 activa Team Create y suma las cuentas de Roblox de @TachyonWasTaken y @vFrangi (completar la tabla de `docs/ONBOARDING.md` y `docs/OWNERS.md`).
- [ ] Escribir la descripción corta del juego (CLAUDE.md, README.md).
- [ ] Borrar `src/shared/Hello.luau` y los scripts de ejemplo cuando exista código real.

## Bugs conocidos
| Bug | Sistema | Prioridad | Notas |
|---|---|---|---|
| En el Output aparece `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` al dar Play | Plugin de Rojo | Baja | Causa encontrada: el plugin de Rojo tiene `Sounds.Notification = rbxassetid://203785492` y al arrancar lo precarga con `ContentProvider:PreloadAsync`, que lo pide como imagen. No es del juego y no hace daño. Sale de a dos porque hay dos plugins de Rojo instalados (el de la tienda y el `RojoManagedPlugin` local). |

## Última actualización
- 2026-11-27 — Armas en primera persona: viewmodel, munición, recarga, inspección y pose de correr (`feature/viewmodel`).
- 2026-11-25 — Sistema de Armas pasado de Studio a Git (`feature/armas`).
- 2026-11-25 — Arreglos de la auditoría del entorno (`fix/post-auditoria`).
- 2026-11-25 — Setup y verificación del entorno (`setup/entorno`).
- 2026-11-23 — Estructura inicial del proyecto (`main`).
