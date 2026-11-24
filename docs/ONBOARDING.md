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
Verificá: `rojo --version`, `selene --version`, `stylua --version`.

## 4. Rojo en Studio
1. Instalá el plugin: `rojo plugin install` (o desde la Creator Store, plugin "Rojo" de rojo-rbx).
2. Abrí el lugar del juego en Studio (Team Create).
3. En la carpeta del repo: `rojo serve`.
4. En Studio: pestaña Plugins → Rojo → **Connect**.
5. Dale a Play: en el Output tienen que aparecer `[Shared] Sincronización OK desde el servidor` y `... desde el cliente`.

> Rojo solo maneja el código de `src/`. El arte, los mapas y la UI hecha a mano en Studio no se borran (`$ignoreUnknownInstances`).

## 5. Conectar el MCP de Roblox Studio a Claude Code
No hay `.mcp.json` en el repo porque la ruta cambia en cada máquina. Cada uno lo conecta desde Studio:
1. En Studio abrí el **Assistant**.
2. Menú **…** → **Manage MCP Servers**.
3. Activá **Enable Studio as MCP server**.
4. En la lista de clientes, usá el **quick connect** de **Claude Code**.
5. Reiniciá Claude Code y comprobá que aparecen las herramientas del MCP de Studio (por ejemplo, preguntale "¿qué lugar tengo abierto en Studio?").

## 6. Claude Code
- La configuración compartida ya viene en el repo: `CLAUDE.md`, `.claude/settings.json` (permisos + hook de StyLua/Selene) y las skills `/inicio`, `/cierre`, `/nuevo-sistema`, `/revisar-pr`.
- Preferencias personales: creá `CLAUDE.local.md` en la raíz (no se sube). Ejemplo: "Soy X, trabajo en la UI, explicame los cambios paso a paso".
- Permisos personales extra: `.claude/settings.local.json` (tampoco se sube).

## 7. VS Code (opcional)
Abrí la carpeta y aceptá las extensiones recomendadas (Rojo, Luau LSP, Selene, StyLua). Formatea al guardar.

## 8. Primer día
1. Leé `CLAUDE.md`, `docs/PROJECT_STATE.md`, `docs/ARCHITECTURE.md` y `docs/OWNERS.md`.
2. En Claude Code: `/inicio`.
3. Trabajá en una rama, cerrá con `/cierre` y abrí el PR.
