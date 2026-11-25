---
name: nuevo-sistema
description: Crea la estructura de un sistema nuevo del juego (módulos en server, client y/o shared según corresponda) y su doc a partir de docs/systems/_TEMPLATE.md, y lo registra en ARCHITECTURE.md y PROJECT_STATE.md. Usar cuando se empieza un sistema que todavía no existe (tienda, inventario, combate, etc.).
disable-model-invocation: true
argument-hint: "<NombreDelSistema>"
---

# /nuevo-sistema — crear un sistema

Respondé en español. Sistema pedido: `$ARGUMENTS` (si está vacío, preguntá el nombre).

1. **Chequeos previos**
   - Confirmá que no estoy en `main`. Si lo estoy, proponé `git switch -c feature/<sistema>`.
   - Leé `docs/ARCHITECTURE.md` y fijate que el sistema no exista ya (también buscá en `src/`).

2. **Preguntá (todo junto)**
   - Qué hace en 1–2 líneas.
   - Qué partes necesita: server, client, shared (sugerí según el propósito; la lógica importante siempre va al server).
   - Si guarda datos (DataStore) y qué RemoteEvents necesita (nombre, dirección, argumentos).

3. **Crear archivos** (nombre en PascalCase, `--!strict`, servicios con `GetService`, API pública tipada, `task.*`):
   - Server: `src/server/<Sistema>Service.luau` → tabla con `start(): ()` y funciones públicas tipadas. Crea sus remotes en `ReplicatedStorage.Remotes` y **valida cada argumento** (tipo, rango, NaN, distancia, cooldown, propiedad del ítem/plata).
   - Client: `src/client/<Sistema>Controller.luau` → `start(): ()`, espera los remotes con `WaitForChild` y solo envía intenciones.
   - Shared: `src/shared/<Sistema>/Types.luau` (con `export type`) y/o `Config.luau` si hace falta.
   - Registrá el `start()` en `src/server/Main.server.luau` / `src/client/Main.client.luau`.

4. **Doc**: copiá `docs/systems/_TEMPLATE.md` a `docs/systems/<Sistema>.md` y completalo (propósito, archivos, API, remotes, datos, trampas, cómo testearlo).

5. **Registrar**
   - `docs/ARCHITECTURE.md`: fila en "Mapa de sistemas", remotes en la tabla de RemoteEvents (con la columna de validación) y DataStores si aplica.
   - `docs/PROJECT_STATE.md`: agregar a "En progreso" (quién / rama).

6. **Verificar**: `stylua src`, `selene src`, y playtest con el MCP de Studio (con `rojo serve` corriendo) para confirmar que el sistema arranca sin errores en el Output.

7. Resumí los archivos creados y sugerí los próximos pasos (y `/cierre` al terminar).
