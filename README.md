# Roblox_Game

**Arena de AK-47** — (descripción pendiente).

Repositorio del equipo: tres cocreadores y codueños con el mismo rango (@RamiRoblox, @TachyonWasTaken, @vFrangi). Cada miembro programa con **Claude Code**, y las 3 IAs comparten el mismo contexto a través de archivos versionados: `CLAUDE.md`, `docs/` y `.claude/`.

## Stack
- **Luau** con `--!strict`
- **Rojo**: sincroniza `src/` con Roblox Studio
- **Roblox Studio MCP**: la IA hace playtests y lee el Output
- **Rokit** (herramientas), **Wally** (paquetes), **Selene** (linter), **StyLua** (formato), **luau-lsp**
- **GitHub**: ramas, Pull Requests y CI

## Place del equipo
| Dato | Valor |
|---|---|
| Place | **Lugar de H1P3R_10** |
| placeId | `75368429466226` |
| Dueño | cuenta de Roblox **H1P3R_10** (@RamiRoblox) |

Se comparte por **Team Create**. Cómo pedir acceso, abrirlo y conectar Rojo: [docs/ONBOARDING.md](docs/ONBOARDING.md#5-place-del-equipo-y-team-create).
> ⚠️ El código se edita **solo en `src/`**. Rojo pisa los scripts sincronizados del place: lo que edites dentro de Studio en esas carpetas se pierde.

## Requisitos
Git (en Windows incluye Git Bash), GitHub CLI (`gh`), Rokit, Roblox Studio y Claude Code. VS Code es opcional. La guía completa está en [docs/ONBOARDING.md](docs/ONBOARDING.md).

## Setup (cada miembro)
0. **Git por primera vez:** `git config --global user.name` y `user.email` (ver [ONBOARDING](docs/ONBOARDING.md#2-git-y-github)).
1. **Clonar**
   ```
   git clone https://github.com/RamiRoblox/Roblox_Game.git
   cd Roblox_Game
   ```
2. **Herramientas:** `rokit install` (pregunta si confiás en cada herramienta: respondé que **sí** a todas)
3. **Paquetes:** `wally install`
4. **Plugin de Rojo en Studio:** `rojo plugin install` con Studio cerrado (si estaba abierto, reinicialo)
5. **Sincronizar:** `rojo serve` (puerto 34872) → en Studio, Plugins → Rojo → Connect. La primera vez, hacelo en un **Baseplate nuevo**; después, en el place del equipo (Team Create).
6. **Conectar el MCP de Studio a Claude Code:** en Studio, Assistant → **…** → Manage MCP Servers → *Enable Studio as MCP server* → quick connect de **Claude Code**. Si Claude Code no ve las herramientas de Studio, reinicialo.
   > No subimos `.mcp.json`: la ruta depende de cada máquina, así que cada uno lo conecta desde Studio.
7. **Probar:** Play en Studio. En el Output tiene que aparecer `Sincronización OK` del servidor y del cliente.
8. **VS Code (opcional):** instalá las 4 extensiones recomendadas en `.vscode/extensions.json`.

Si algo falla, mirá **Problemas comunes** en [docs/ONBOARDING.md](docs/ONBOARDING.md#problemas-comunes).

## Flujo diario
```
/inicio  →  rama feature/<nombre> o fix/<nombre>  →  trabajar (+ playtest con MCP)  →  /cierre  →  PR  →  review  →  merge
```
| Comando | Qué hace |
|---|---|
| `/inicio` | `git pull`, muestra la rama, lee el estado y la arquitectura, pregunta en qué vas a trabajar y sugiere la rama |
| `/cierre` | revisa el diff, corre Selene y StyLua, actualiza los docs, hace commit y push, y ofrece abrir el PR |
| `/nuevo-sistema` | crea los módulos y el doc de un sistema nuevo y lo registra en ARCHITECTURE |
| `/revisar-pr` | revisa el PR de un compañero (solo lectura): seguridad de los remotes, roturas y docs |

## Reglas
- 🚫 **Nunca pushear directo a `main`.** Todo entra por Pull Request con el CI en verde.
  > GitHub **no** puede hacer cumplir esta regla en este repo: la protección de ramas en repos privados requiere GitHub Pro/Team. Depende de nosotros, de las reglas de `CLAUDE.md` y de los `deny` de `.claude/settings.json`, que bloquean que Claude haga push a `main` o `--force`, y de un hook que bloquea cualquier `git push` mientras la rama actual sea `main`.
- No hay dueños por sistema: cualquiera trabaja en cualquier sistema. **Cada PR lo revisa al menos uno de los otros dos** (ver [docs/OWNERS.md](docs/OWNERS.md)).
- El servidor valida todo lo que llega del cliente. Más reglas en [CLAUDE.md](CLAUDE.md).

## Comandos útiles
| Comando | Para qué |
|---|---|
| `rojo serve` | sincronizar con Studio |
| `rojo build -o build.rbxl` | generar un lugar (no se versiona) |
| `selene src` | linter |
| `stylua src` / `stylua --check src` | formatear / verificar formato |
| `wally install` | instalar los paquetes de `wally.toml` |

## Estructura
```
src/server  → ServerScriptService
src/client  → StarterPlayer.StarterPlayerScripts
src/shared  → ReplicatedStorage.Shared
Packages/   → ReplicatedStorage.Packages (Wally, no se versiona)
docs/       → estado, arquitectura, decisiones, equipo, docs por sistema
.claude/    → config compartida de Claude Code (hooks + skills)
```

## Invitar colaboradores a GitHub (admin del repo)
> ⚠️ **Reemplazá `USUARIO_DE_GITHUB_REAL` por el usuario exacto de la persona antes de correrlo.** Si lo copiás tal cual, o con un nombre inventado, GitHub invita a la cuenta que tenga ese nombre (puede ser un desconocido) con permiso de escritura. Ya pasó una vez.

```
gh api -X PUT repos/RamiRoblox/Roblox_Game/collaborators/USUARIO_DE_GITHUB_REAL -f permission=push
```
Después verificá a quién invitaste y cancelá cualquier invitación que no sea de un compañero:
```
gh api repos/RamiRoblox/Roblox_Game/invitations --jq '.[] | "\(.id) \(.invitee.login)"'
gh api -X DELETE repos/RamiRoblox/Roblox_Game/invitations/ID_DE_LA_INVITACION
```
