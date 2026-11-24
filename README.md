# Roblox_Game

**[NOMBRE DEL JUEGO]** — [descripción corta del juego, completar].

Repositorio del equipo (3 personas). Cada miembro programa con **Claude Code**, y las 3 IAs comparten el mismo contexto a través de archivos versionados: `CLAUDE.md`, `docs/` y `.claude/`.

## Stack
- **Luau** con `--!strict`
- **Rojo**: sincroniza `src/` con Roblox Studio
- **Roblox Studio MCP**: la IA hace playtests y lee el Output
- **Rokit** (herramientas), **Wally** (paquetes), **Selene** (linter), **StyLua** (formato), **luau-lsp**
- **GitHub**: ramas, Pull Requests y CI

## Requisitos
Git (en Windows incluye Git Bash), GitHub CLI (`gh`), Rokit, Roblox Studio y Claude Code. VS Code es opcional. La guía completa está en [docs/ONBOARDING.md](docs/ONBOARDING.md).

## Setup (cada miembro)
1. **Clonar**
   ```
   git clone https://github.com/RamiRoblox/Roblox_Game.git
   cd Roblox_Game
   ```
2. **Herramientas:** `rokit install` (aceptá confiar en cada herramienta)
3. **Paquetes:** `wally install`
4. **Plugin de Rojo en Studio:** `rojo plugin install`
5. **Sincronizar:** `rojo serve` → en Studio, Plugins → Rojo → Connect
6. **Conectar el MCP de Studio a Claude Code:** en Studio, Assistant → **…** → Manage MCP Servers → *Enable Studio as MCP server* → quick connect de **Claude Code**. Reiniciá Claude Code.
   > No subimos `.mcp.json`: la ruta depende de cada máquina, así que cada uno lo conecta desde Studio.
7. **Probar:** Play en Studio. En el Output tiene que aparecer `Sincronización OK` del servidor y del cliente.

## Flujo diario
```
/inicio  →  rama feature/<nombre> o fix/<nombre>  →  trabajar (+ playtest con MCP)  →  /cierre  →  PR  →  review  →  merge
```
| Comando | Qué hace |
|---|---|
| `/inicio` | `git pull`, muestra la rama, lee el estado y la arquitectura, pregunta en qué vas a trabajar y sugiere la rama |
| `/cierre` | revisa el diff, corre Selene y StyLua, actualiza los docs, hace commit y push, y ofrece abrir el PR |
| `/nuevo-sistema` | crea los módulos y el doc de un sistema nuevo y lo registra en ARCHITECTURE y OWNERS |
| `/revisar-pr` | revisa el PR de un compañero (solo lectura): seguridad de los remotes, roturas y docs |

## Reglas
- 🚫 **Nunca pushear directo a `main`.** Todo entra por Pull Request con el CI en verde.
- El dueño de un sistema (ver [docs/OWNERS.md](docs/OWNERS.md)) revisa los PRs que lo tocan.
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
docs/       → estado, arquitectura, decisiones, dueños, docs por sistema
.claude/    → config compartida de Claude Code (hooks + skills)
```

## Invitar colaboradores (dueño del repo)
```
gh api -X PUT repos/RamiRoblox/Roblox_Game/collaborators/<usuario> -f permission=push
```
