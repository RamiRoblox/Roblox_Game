# Onboarding — configurar todo desde cero

Pasos para que un miembro nuevo quede listo para programar con Claude Code. Tiempo estimado: 20–30 minutos.

## 1. Programas
| Programa | Windows | Mac |
|---|---|---|
| Git | https://git-scm.com/download/win (incluye **Git Bash**, que usan los hooks de Claude Code) | `xcode-select --install` o `brew install git` |
| GitHub CLI | `winget install GitHub.cli` | `brew install gh` |
| Rokit | Bajar `rokit-*-windows-x86_64.zip` de https://github.com/rojo-rbx/rokit/releases, descomprimir y ejecutar `.\rokit.exe self-install` | `curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh \| bash` |
| Roblox Studio | https://create.roblox.com | igual |
| Claude Code | App de escritorio o CLI (https://claude.com/claude-code) | igual |
| VS Code (opcional) | https://code.visualstudio.com | igual |

Después de instalar Rokit, **cerrá y volvé a abrir la terminal** (y Claude Code) para que tome el PATH.

## 2. GitHub
1. Aceptá la invitación al repo (llega por mail o en https://github.com/notifications).
2. Iniciá sesión en la CLI: `gh auth login` → GitHub.com → HTTPS → navegador.

## 3. Clonar e instalar herramientas
```
git clone https://github.com/RamiRoblox/Roblox_Game.git
cd Roblox_Game
rokit install      # la primera vez pregunta si confiás en cada herramienta: respondé que sí
wally install
```
Verificá que respondan las 5 y que las versiones coincidan con `rokit.toml`: `rojo --version`, `selene --version`, `stylua --version`, `luau-lsp --version`, `wally --version`.
Si `wally.toml` no tiene nada en `[dependencies]`, `wally install` se puede saltear.

## 4. Rojo en Studio
1. Instalá el plugin con **Studio cerrado**: `rojo plugin install`. Queda en `%LOCALAPPDATA%\Roblox\Plugins\RojoManagedPlugin.rbxm` y es siempre la misma versión que el `rojo` de `rokit.toml` (viene dentro del ejecutable). Si Studio estaba abierto, reinicialo para que lo cargue.
2. **La primera vez, probá con un Baseplate nuevo** (File → New → Baseplate), no con un lugar que ya tenga scripts: Rojo reemplaza lo que haya en `ServerScriptService`, `ReplicatedStorage.Shared` y `StarterPlayerScripts` por lo de `src/`.
3. En la carpeta del repo: `rojo serve` (escucha en `localhost:34872`).
4. En Studio: pestaña **Plugins** → **Rojo** → verificá `localhost` / `34872` → **Connect**.
5. En el Explorer tienen que aparecer `ServerScriptService.Main`, `StarterPlayer.StarterPlayerScripts.Main` y `ReplicatedStorage.Shared.Hello`.
6. Dale a Play: en el Output tienen que aparecer `[Shared] Sincronización OK desde el servidor` y `... desde el cliente`.
7. Probá el sync en vivo: cambiá un `print` en `src/server/Main.server.luau`, guardá y mirá que el script cambie en Studio sin hacer nada más.

> Rojo solo maneja el código de `src/`. El arte, los mapas y la UI hecha a mano en Studio no se borran (`$ignoreUnknownInstances`).

## 5. Conectar el MCP de Roblox Studio a Claude Code
No hay `.mcp.json` en el repo porque la ruta cambia en cada máquina. Cada uno lo conecta desde Studio:
1. En Studio abrí el **Assistant**.
2. Menú **…** → **Manage MCP Servers**.
3. Activá **Enable Studio as MCP server**.
4. En la lista de clientes, usá el **quick connect** de **Claude Code**.
5. Comprobá que Claude Code ve el MCP: preguntale "¿qué lugar tengo abierto en Studio?". En la app de escritorio de Claude Code suele tomarlo sin reiniciar; si no aparecen las herramientas de Studio, reiniciá la sesión de Claude Code.
6. Si reiniciás Studio y el MCP deja de responder, revisá que **Enable Studio as MCP server** siga activo.

## 6. Claude Code
- La configuración compartida ya viene en el repo: `CLAUDE.md`, `.claude/settings.json` (permisos + hook de StyLua/Selene) y las skills `/inicio`, `/cierre`, `/nuevo-sistema`, `/revisar-pr`.
- Preferencias personales: creá `CLAUDE.local.md` en la raíz (no se sube). Ejemplo: "Soy X, trabajo en la UI, explicame los cambios paso a paso".
- Permisos personales extra: `.claude/settings.local.json` (tampoco se sube).

## 7. VS Code (opcional)
1. Comprobá que el comando `code` funcione en la terminal (`code --version`). Si no, mirá "Problemas comunes".
2. Instalá las extensiones (o aceptá las recomendadas al abrir la carpeta):
   ```
   code --install-extension evaera.vscode-rojo
   code --install-extension JohnnyMorganz.luau-lsp
   code --install-extension Kampfkarren.selene-vscode
   code --install-extension JohnnyMorganz.stylua
   ```
3. `.vscode/settings.json` ya viene configurado: luau-lsp con tipos de Roblox y sourcemap de Rojo autogenerado, StyLua como formateador al guardar (usando el StyLua de Rokit, el mismo que el CI) y Selene revisando mientras escribís.

## 8. Primer día
1. Leé `CLAUDE.md`, `docs/PROJECT_STATE.md`, `docs/ARCHITECTURE.md` y `docs/OWNERS.md`.
2. En Claude Code: `/inicio`.
3. Trabajá en una rama, cerrá con `/cierre` y abrí el PR.

## Problemas comunes
| Síntoma | Causa | Solución |
|---|---|---|
| `code: command not found` aunque VS Code está instalado y su carpeta `bin` está en el PATH | VS Code se instaló o actualizó **mientras otra copia estaba abierta**: la instalación queda a medias, con archivos `new_Code.exe`, `bin\new_code.cmd` y un archivo `updating_version`, y no existe `bin\code.cmd`. | Cerrá **todas** las ventanas de VS Code (revisá en el Administrador de tareas que no quede ningún `Code.exe`), volvé a correr el instalador de https://code.visualstudio.com con la opción **Add to PATH** marcada y abrí una terminal nueva. |
| No aparece Rojo en la pestaña Plugins | Se corrió `rojo plugin install` con Studio abierto. | Reiniciá Studio. |
| Rojo no conecta y dice algo de versión / protocolo | El plugin quedó de otra versión de Rojo (por ejemplo, después de `rokit update rojo`). | Con Studio cerrado: `rojo plugin install` otra vez. |
| En Play aparece `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` | Viene de Studio o de un plugin, no del proyecto (ese id no está en ningún objeto del juego). | Se puede ignorar. |
| VS Code formatea distinto que el CI | La extensión de StyLua bajó su propia versión. | Dejá `stylua.searchBinaryInPATH: true` (ya está en `.vscode/settings.json`) y que Rokit esté en el PATH. La extensión de Selene no tiene esa opción y baja su propio Selene: ante la duda, lo que vale es `selene src` en la terminal (misma versión que el CI). |
| Queda un `rokit.exe` en la carpeta del repo | Se descomprimió el instalador de Rokit ahí. | No se sube (`*.exe` está en `.gitignore`). Después de `rokit self-install` se puede borrar. |
