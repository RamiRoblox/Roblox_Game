# Onboarding — configurar todo desde cero

Pasos para que un miembro nuevo de **Arena de AK-47** quede listo para programar con Claude Code. Tiempo estimado: 30–40 minutos.

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

## 2. Git y GitHub
1. **Si es la primera vez que usás Git en esta computadora**, decile quién sos (es lo que aparece como autor de cada commit):
   ```
   git config --global user.name "TU_USUARIO_DE_GITHUB"
   git config --global user.email "TU_MAIL_DE_GITHUB"
   ```
   Reemplazá los dos valores. Para no publicar tu mail real podés usar el mail privado que te da GitHub en https://github.com/settings/emails (termina en `@users.noreply.github.com`). Comprobalo con `git config --global --list`.
2. Aceptá la invitación al repo (llega por mail o en https://github.com/notifications).
3. Iniciá sesión en la CLI: `gh auth login` → GitHub.com → HTTPS → **Yes** a "Authenticate Git with your GitHub credentials" → navegador. Comprobalo con `gh auth status`.

## 3. Clonar e instalar herramientas
```
git clone https://github.com/RamiRoblox/Roblox_Game.git
cd Roblox_Game
rokit install
wally install
```
**La pregunta de `rokit install`:** la primera vez, Rokit pregunta por cada herramienta (rojo, selene, stylua, luau-lsp, wally) si confiás en ella, porque se baja de GitHub de un autor que todavía no aprobaste en tu computadora. **Respondé que sí a todas.** Si respondés que no, esa herramienta no se instala y después el comando falla con `Failed to find tool ...`. Se arregla corriendo `rokit install` otra vez y aceptando (o `rokit trust <autor>/<herramienta>`, por ejemplo `rokit trust rojo-rbx/rojo`).

Verificá que respondan las 5 y que las versiones coincidan con `rokit.toml`: `rojo --version`, `selene --version`, `stylua --version`, `luau-lsp --version`, `wally --version`.
Si `wally.toml` no tiene nada en `[dependencies]`, `wally install` se puede saltear.

## 4. Rojo en Studio (prueba en un Baseplate)
1. Instalá el plugin con **Studio cerrado**: `rojo plugin install`. Queda en `%LOCALAPPDATA%\Roblox\Plugins\RojoManagedPlugin.rbxm` y es siempre la misma versión que el `rojo` de `rokit.toml` (viene dentro del ejecutable). Si Studio estaba abierto, reinicialo para que lo cargue.
2. **La primera vez, probá con un Baseplate nuevo** (File → New → Baseplate), no con el place del equipo: así ves que todo funciona sin riesgo.
3. En la carpeta del repo: `rojo serve` (escucha en `localhost:34872`).
4. En Studio: pestaña **Plugins** → **Rojo** → verificá `localhost` / `34872` → **Connect**.
5. En el Explorer tienen que aparecer `ServerScriptService.Main`, `StarterPlayer.StarterPlayerScripts.Main` y `ReplicatedStorage.Shared.Hello`.
6. Dale a Play: en el Output tienen que aparecer `[Shared] Sincronización OK desde el servidor` y `... desde el cliente`.
7. Probá el sync en vivo: cambiá un `print` en `src/server/Main.server.luau`, guardá y mirá que el script cambie en Studio sin hacer nada más. Después deshacé el cambio.

## 5. Place del equipo y Team Create
| Dato | Valor |
|---|---|
| Place | **Lugar de H1P3R_10** |
| placeId | `75368429466226` |
| Dueño | cuenta de Roblox **H1P3R_10** (@RamiRoblox) |

### 5.1 Cuentas de cada uno
Para dar acceso por Team Create hace falta el usuario de Roblox de cada uno. Cuando lo tengas, pasáselo a @RamiRoblox y actualizá esta tabla (y la de `docs/OWNERS.md`) en un PR.

| Usuario de GitHub | Usuario de Roblox | Acceso al place |
|---|---|---|
| @RamiRoblox | H1P3R_10 | dueño |
| @TachyonWasTaken | _pendiente_ | _pendiente_ |
| @vFrangi | _pendiente_ | _pendiente_ |

### 5.2 Activar Team Create y sumar compañeros (lo hace H1P3R_10, una sola vez)
1. Abrí el place en Studio con la cuenta **H1P3R_10**.
2. Activá Team Create: **File → Collaborate** (o el botón **Collaborate** de la barra). Si te pide publicar, el place ya está publicado: elegí el existente.
3. Abrí **File → Game Settings → Permissions**.
4. En **Collaborators**, buscá el usuario de Roblox de cada compañero, agregalo y dale permiso **Edit**. Si Studio no lo encuentra o no te deja agregarlo, primero agregalo como amigo en Roblox (en experiencias de una cuenta personal, Studio puede pedir que sean amigos).
5. **Save**. A cada compañero le llega la invitación en Studio.

### 5.3 Abrir el place y conectar Rojo (cada uno)
1. Abrí Studio con tu cuenta de Roblox. En la pantalla de inicio, pestaña de experiencias **compartidas conmigo** (*Shared with me*), abrí **Lugar de H1P3R_10**. Si no aparece, revisá que H1P3R_10 te haya agregado (5.2).
2. En la terminal, en la carpeta del repo y **en tu rama de trabajo**: `rojo serve`.
3. En Studio: **Plugins → Rojo → Connect**. Rojo escribe en el place el código de `src/` de tu rama.
4. Para desconectar: **Disconnect** en el plugin y `Ctrl+C` en la terminal.

> ⚠️ **El código se cambia solo desde el repo.** Rojo pisa los scripts de las carpetas sincronizadas (`ServerScriptService`, `ReplicatedStorage.Shared`, `StarterPlayer.StarterPlayerScripts`) con lo que hay en `src/`. Si editás uno de esos scripts dentro de Studio, el cambio se pierde la próxima vez que alguien conecte Rojo, y además no queda en Git. Editá siempre los archivos en `src/` (Claude Code, VS Code) y dejá que Rojo los sincronice.
>
> ⚠️ **Team Create es compartido:** lo que Rojo escribe en el place lo ven los tres al instante. Si dos personas conectan Rojo al mismo tiempo desde ramas distintas, se pisan el código entre sí. Avisá en el grupo antes de conectar Rojo al place del equipo, o, para probar tu rama sola, usá una copia local (**File → Save to File As…** un `.rbxl`, que Git ignora) y conectá Rojo ahí.
>
> Rojo no toca el resto: el arte, los mapas y la UI hecha a mano en Studio no se borran (`$ignoreUnknownInstances`).

## 6. Conectar el MCP de Roblox Studio a Claude Code
No hay `.mcp.json` en el repo porque la ruta cambia en cada máquina. Cada uno lo conecta desde Studio:
1. En Studio abrí el **Assistant**.
2. Menú **…** → **Manage MCP Servers**.
3. Activá **Enable Studio as MCP server**.
4. En la lista de clientes, usá el **quick connect** de **Claude Code**.
5. Comprobá que Claude Code ve el MCP: preguntale "¿qué lugar tengo abierto en Studio?". En la app de escritorio de Claude Code suele tomarlo sin reiniciar; si no aparecen las herramientas de Studio, reiniciá la sesión de Claude Code.
6. Si reiniciás Studio y el MCP deja de responder, revisá que **Enable Studio as MCP server** siga activo.

## 7. Claude Code
- **Iniciá sesión** la primera vez (app de escritorio, o `claude` en la terminal y después `/login`).
- **Aceptá el diálogo de confianza de la carpeta.** La primera vez que abrís Claude Code dentro del clon, pregunta si confiás en la carpeta: respondé que **sí**. Si no lo aceptás, Claude Code **ignora los permisos de `.claude/settings.json`** ("Ignoring ... permissions.allow entries ... this workspace has not been trusted") y los hooks de StyLua/Selene y de `git push` pueden no correr. Tampoco alcanza con usar `claude -p` en un clon recién bajado: primero abrilo una vez de forma interactiva.
- **Comprobá que todo cargó** (una sola vez, en el clon): escribí `/inicio` y verificá que aparezca. Después editá un `.luau` a propósito con mal formato (por ejemplo `local x=1`) y comprobá que el hook lo reformatea. Si el hook avisa "no se encontró stylua/selene", corré `rokit install` (paso 3).
- La configuración compartida ya viene en el repo: `CLAUDE.md`, `.claude/settings.json` (permisos, hook de StyLua/Selene y hook que bloquea `git push` estando en `main`) y las skills `/inicio`, `/cierre`, `/nuevo-sistema`, `/revisar-pr`.
- Preferencias personales: creá `CLAUDE.local.md` en la raíz (no se sube). Ejemplo: "Soy X, hoy trabajo en la UI, explicame los cambios paso a paso".
- Permisos personales extra: `.claude/settings.local.json` (tampoco se sube).

## 8. VS Code (opcional)
1. Comprobá que el comando `code` funcione en la terminal (`code --version`). Si no, mirá "Problemas comunes".
2. Instalá las extensiones (o aceptá las recomendadas al abrir la carpeta):
   ```
   code --install-extension evaera.vscode-rojo
   code --install-extension JohnnyMorganz.luau-lsp
   code --install-extension Kampfkarren.selene-vscode
   code --install-extension JohnnyMorganz.stylua
   ```
3. `.vscode/settings.json` ya viene configurado: luau-lsp con tipos de Roblox y sourcemap de Rojo autogenerado, StyLua como formateador al guardar (usando el StyLua de Rokit, el mismo que el CI) y Selene revisando mientras escribís.

## 9. Primer día
1. Leé `CLAUDE.md`, `docs/PROJECT_STATE.md`, `docs/ARCHITECTURE.md` y `docs/OWNERS.md` (equipo y regla de revisión cruzada).
2. En Claude Code: `/inicio`.
3. Trabajá en una rama, cerrá con `/cierre`, abrí el PR y pedile review a uno de los otros dos.

## Problemas comunes
| Síntoma | Causa | Solución |
|---|---|---|
| `code: command not found` aunque VS Code está instalado y su carpeta `bin` está en el PATH | VS Code se instaló o actualizó **mientras otra copia estaba abierta**: la instalación queda a medias, con archivos `new_Code.exe`, `bin\new_code.cmd` y un archivo `updating_version`, y no existe `bin\code.cmd`. | Cerrá **todas** las ventanas de VS Code (revisá en el Administrador de tareas que no quede ningún `Code.exe`), volvé a correr el instalador de https://code.visualstudio.com con la opción **Add to PATH** marcada y abrí una terminal nueva. |
| Claude Code dice "Ignoring ... permissions.allow entries ... workspace has not been trusted", o los hooks no corren | No se aceptó el diálogo de confianza de la carpeta. | Abrí Claude Code de forma interactiva en el clon y aceptá la confianza (paso 7). |
| Un aviso "StyLua/Selene no se encontraron" después de editar un `.luau` | El hook no puede formatear ni lintear porque falta `rokit install` (o el PATH de Rokit). | `rokit install` y reiniciá la terminal / Claude Code. |
| En Play aparecen `Script timeout: exhausted allowed execution time` de `CoreGui...` (ChromeService, SelfieView, etc.) | Scripts internos de Roblox que se retrasan al arrancar el playtest en Studio; no son del proyecto. | Se pueden ignorar si no hay errores de `src/`. |
| `Failed to find tool ...` al correr `rojo`, `selene`, etc. | No se corrió `rokit install`, o se respondió que no a la pregunta de confianza. | `rokit install` en la carpeta del repo y aceptá. |
| `git commit` falla con "Please tell me who you are" | Falta configurar Git. | Paso 2.1 (`git config --global user.name` / `user.email`). |
| Claude Code dice "No se puede hacer git push estando en main" | Es a propósito: un hook bloquea pushear a `main`. | Creá una rama (`git switch -c feature/<nombre>`), pusheá esa y abrí un PR. |
| No aparece Rojo en la pestaña Plugins | Se corrió `rojo plugin install` con Studio abierto. | Reiniciá Studio. |
| Rojo no conecta y dice algo de versión / protocolo | El plugin quedó de otra versión de Rojo (por ejemplo, después de `rokit update rojo`). | Con Studio cerrado: `rojo plugin install` otra vez. |
| `rojo serve` dice que el puerto 34872 está en uso | Ya hay otro `rojo serve` abierto (otra terminal o VS Code). | Usá ese, o cerralo antes de abrir otro. |
| Un cambio hecho en un script dentro de Studio desapareció | Rojo lo pisó con la versión de `src/`. | El código se edita solo en el repo (ver 5.3). |
| En Play aparece `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` | Viene de Studio o de un plugin, no del proyecto (ese id no está en ningún objeto del juego). | Se puede ignorar. |
| VS Code formatea distinto que el CI | La extensión de StyLua bajó su propia versión. | Dejá `stylua.searchBinaryInPATH: true` (ya está en `.vscode/settings.json`) y que Rokit esté en el PATH. La extensión de Selene no tiene esa opción y baja su propio Selene: ante la duda, lo que vale es `selene src` en la terminal (misma versión que el CI). |
| Queda un `rokit.exe` en la carpeta del repo | Se descomprimió el instalador de Rokit ahí. | No se sube (`*.exe` está en `.gitignore`). Después de `rokit self-install` se puede borrar. |
