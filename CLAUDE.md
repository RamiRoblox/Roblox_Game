# CLAUDE.md — Roblox_Game

Contexto compartido para las 3 instancias de Claude Code del equipo. Respondé siempre en **español**.

## Proyecto
- **Juego:** [NOMBRE DEL JUEGO] — [descripción corta, completar].
- **Equipo:** 3 personas, cada una con Claude Code. Dueños de sistemas en `docs/OWNERS.md`.
- **Stack:** Luau + **Rojo** (código en `src/` ↔ Studio) + **Roblox Studio MCP** (playtest, Output, escena) + **Git/GitHub** (ramas y PRs).
- El código vive en Git. El arte, los mapas y la UI hecha a mano viven en el lugar de Studio (Team Create). Rojo tiene `$ignoreUnknownInstances` para no borrarlos.

## Estructura
| Carpeta | Destino en Roblox |
|---|---|
| `src/server` | `ServerScriptService` |
| `src/client` | `StarterPlayer.StarterPlayerScripts` |
| `src/shared` | `ReplicatedStorage.Shared` |
| `Packages/` (Wally, no se versiona) | `ReplicatedStorage.Packages` |

Convención de archivos: `*.server.luau` = Script, `*.client.luau` = LocalScript, `*.luau` = ModuleScript.

## Comandos
```
rokit install            # instala rojo, selene, stylua, luau-lsp, wally (versiones en rokit.toml)
wally install            # baja los paquetes a Packages/
rojo serve               # sincroniza con Studio (plugin de Rojo → Connect)
rojo sourcemap -o sourcemap.json   # para luau-lsp
selene src               # linter
stylua src               # formatear (stylua --check src para solo verificar)
```

## Documentación (leer antes de tocar código)
- `docs/PROJECT_STATE.md` — qué está hecho, en progreso, próximo y bugs conocidos.
- `docs/ARCHITECTURE.md` — mapa de sistemas, tabla de RemoteEvents y flujo cliente↔servidor.
- `docs/systems/<Sistema>.md` — doc de cada sistema (plantilla: `docs/systems/_TEMPLATE.md`).
- `docs/DECISIONS.md` — decisiones tomadas y por qué.
- `docs/OWNERS.md` — quién es dueño de cada sistema.

## Reglas de trabajo (obligatorias)
1. **Antes de modificar un sistema**, leer `docs/PROJECT_STATE.md` y `docs/systems/<Sistema>.md`. Si el doc no existe, **crearlo primero** a partir de la plantilla, analizando el código actual.
2. **Nunca trabajar directo en `main`.** Siempre en una rama (`feature/<nombre>` o `fix/<nombre>`) y unir con Pull Request. Nunca `git push` a `main` ni `--force` sobre ramas ajenas.
3. **Sistemas con dueño:** no hacer cambios grandes en un sistema ajeno sin avisar. El dueño revisa el PR.
4. **Al terminar una tarea**, actualizar `docs/PROJECT_STATE.md` y el doc del sistema tocado. Si se decidió algo de arquitectura, sumar una entrada a `docs/DECISIONS.md`. Si cambió un RemoteEvent, actualizar la tabla de `docs/ARCHITECTURE.md`.
5. **Errores repetidos:** cuando la IA comete el mismo error dos veces, la corrección se agrega a la sección "Errores aprendidos" de este archivo (en un PR).
6. Flujo diario: `/inicio` → rama → trabajar → `/cierre` → PR. Para sistemas nuevos: `/nuevo-sistema`. Para revisar a un compañero: `/revisar-pr`.

## Reglas de Roblox / Luau
- **Never trust the client.** El servidor valida TODO lo que llega por RemoteEvents/RemoteFunctions:
  - tipos (`typeof`), `nil`, NaN e infinitos (`x ~= x`, `math.abs(x) == math.huge`);
  - rangos y números negativos, largo de strings y tablas;
  - distancia del jugador al objetivo, cooldowns/rate-limit por jugador;
  - que el jugador realmente tenga el ítem, la plata o el permiso.
  - Si algo no valida: ignorar (y opcionalmente loguear), nunca `error()` que tire el handler.
- **La lógica importante vive en el servidor:** monedas, daño, inventario, compras, recompensas. El cliente solo pide y muestra.
- `MarketplaceService.ProcessReceipt` **solo en el servidor**, en un único lugar, idempotente (guardar el `PurchaseId`) y devolviendo `PurchaseGranted` solo después de guardar.
- Usar `task.wait` / `task.spawn` / `task.delay` / `task.defer`. **Nunca** `wait` / `spawn` / `delay`.
- `--!strict` en todos los archivos. Tipos de Luau en las APIs públicas de los módulos (parámetros y retorno; `export type` para las estructuras compartidas).
- Servicios siempre con `game:GetService("...")`, al principio del archivo.
- DataStores **siempre dentro de `pcall`**, con reintentos, `UpdateAsync` para datos críticos y guardado en `PlayerRemoving` + `game:BindToClose`.
- Nada de `RemoteFunction` del servidor al cliente (`InvokeClient`): el cliente puede colgar el servidor.
- Conexiones: desconectar o limpiar lo que se crea por jugador cuando el jugador se va.
- **Cambios chicos y verificables:** después de cada cambio, playtest con el MCP de Studio (iniciar Play, revisar el Output/consola, detener) y arreglar errores y warnings antes de seguir.

## Calidad
- Un hook de Claude Code (`.claude/hooks/lint-luau.sh`) corre StyLua y Selene después de cada edición de un `.luau`. Si Selene marca algo, arreglarlo.
- Selene usa `luau_rules.yml` (std de Roblox + `wait`/`spawn`/`delay` marcados como obsoletos).
- El CI de GitHub corre `selene src` y `stylua --check src` en cada PR. Un PR en rojo no se une.

## MCP de Roblox Studio
No hay `.mcp.json` en el repo: cada miembro conecta su Studio desde Studio (Assistant → … → Manage MCP Servers → Enable Studio as MCP server → quick connect de Claude Code). Ver `docs/ONBOARDING.md`.

## Preferencias personales
Cada uno puede tener un `CLAUDE.local.md` en la raíz (está en `.gitignore`, no se sube) con sus preferencias: estilo de respuesta, sistemas en los que trabaja, atajos, etc.

## Errores aprendidos
<!-- Formato: - [fecha] Error → corrección. Agregar cuando la IA repite un error. -->
- (vacío por ahora)
