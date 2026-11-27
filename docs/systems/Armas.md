# Armas

- **Creado por:** código escrito directo en Studio; pasado a Git por @vFrangi. Viewmodel, munición y animaciones: @vFrangi (rama `feature/viewmodel`). No hay dueño: cualquiera del equipo puede trabajar acá.
- **Estado:** en progreso (funciona en playtest; falta el sonido del disparo, el contador de balas en pantalla y la tercera persona)
- **Última actualización:** 2026-11-27

## Propósito
Todo lo de las armas (por ahora la AK-47 y su skin Glaciar):
- **Disparo:** el cliente apunta y pide disparar, el servidor valida (cadencia, munición, posición), hace el raycast y aplica el daño, y todos los clientes dibujan los efectos (fogonazo, trazadora, casquillo, impacto).
- **Munición:** cargador de 30 contado por el servidor, recarga con R validada por el servidor.
- **Primera persona (viewmodel):** con el arma en la mano el juego pasa a primera persona y se ve una copia local del arma con los brazos (manga recta alineada con el arma). Balanceo, paso, salto, retroceso del arma y de la cámara, apuntar con clic derecho (zoom), recarga e inspección (V) animadas por código, pose de correr y anti-pared.
- **Tercera persona (por ahora):** la Tool real en la mano, con la mano izquierda en el guardamanos por IK (R15).

NO maneja compra ni skins (las skins son Tools aparte; ver "Skins" en `WeaponConfig`).

## Archivos
| Archivo | Lado | Rol |
|---|---|---|
| `src/server/WeaponService.luau` | Server | Valida el disparo (cadencia por "turnos", munición, cañón cerca del cuerpo), raycast, daño (headshot, sin fuego amigo), recarga (`WeaponReload`), IK de la mano izquierda. |
| `src/client/WeaponController.luau` | Client | Input (clic izq./der., R, V), sesión del arma, primera persona, cadencia del lado cliente, munición predicha, apuntar (FOV y sensibilidad), pose de correr, retroceso de cámara. |
| `src/client/WeaponViewmodel.luau` | Client | Arma clonada + brazos pegados a la cámara; esconde la Tool real solo para el jugador; anti-pared; aplica movimiento, apuntar, correr y animaciones. |
| `src/client/WeaponMotion.luau` | Client | Resortes: balanceo, paso, salto/caída, retroceso del arma y de la cámara. |
| `src/client/WeaponAnimations.luau` | Client | Recarga e inspección hechas por código (mueve el arma, el `Mag` y el `Bolt` por sus Motor6D, y las manos). |
| `src/client/WeaponTuning.luau` | Client | Modo ajuste (solo Studio): `ReplicatedStorage.AjustesArma` con los valores de `ViewmodelConfig` como atributos editables en vivo. |
| `src/client/WeaponEffects.luau` | Client | Solo cosmético: fogonazo, luz, sonido, casquillo, trazadora e impacto. |
| `src/shared/Weapons/WeaponConfig.luau` | Shared | Stats de cada arma (clave = `Name` de la Tool), skins, nombres de RemoteEvents y atributos. |
| `src/shared/Weapons/ViewmodelConfig.luau` | Shared | **Todos** los valores de "sensación" en primera persona (posición, tamaño, brazos, balanceo, paso, salto, retroceso, apuntar, correr, recarga, inspección, anti-pared). |

Fuera de Git (viven en Studio): las Tools `StarterPack.AK-47` y `StarterPack.AK-47 Glaciar`, los modelos de `ReplicatedStorage.Armas` (AK47, AK47_dorada, AK47_hielo, AK47_Glaciar, AK47_Cristal) y el ModuleScript `ReplicatedStorage.SkinsLegendarias` (código fuera del repo).

## API pública
```lua
-- WeaponConfig (shared)
export type WeaponStats = {
	damage: number, headshotMultiplier: number, fireRate: number, range: number, spreadDegrees: number,
	tracerSpeed: number, magazineSize: number, reloadTime: number, fireSoundId: string,
}
function WeaponConfig.get(weaponName: string): WeaponStats?   -- también resuelve skins ("AK-47 Glaciar" → "AK-47")
WeaponConfig.ammoAttribute = "Municion"        -- atributo que pone el servidor en la Tool
WeaponConfig.reloadingAttribute = "Recargando"

function WeaponService.start(): ()     -- desde Main.server.luau
function WeaponController.start(): ()  -- desde Main.client.luau
function WeaponEffects.playMuzzle(shooter: Model?, toolName: string, origin: Vector3): ()
function WeaponEffects.playMuzzleFrom(muzzle: Attachment?, ejection: Attachment?, toolName: string, origin: Vector3): ()
function WeaponEffects.playBullet(origin: Vector3, endPosition: Vector3, normal: Vector3, hitHumanoid: boolean, speed: number): ()
```
`WeaponViewmodel`, `WeaponMotion`, `WeaponAnimations` y `WeaponTuning` son internos del cliente (los usa `WeaponController`).

## RemoteEvents
Los crea `WeaponService.start()` dentro de `ReplicatedStorage.Remotes`.

| Nombre | Dirección | Argumentos | Validación en el servidor |
|---|---|---|---|
| `WeaponFire` | C→S | `aimPoint: Vector3` | `typeof` Vector3; descarta NaN/inf y coordenadas > 1e6; jugador vivo con una Tool equipada que sea un arma de `WeaponConfig`, con `Handle.Muzzle_Att`; **munición > 0 y no recargando**; cadencia por "turnos" (cada tiro ocupa 60/fireRate s, con 0.1 s de margen por la red: en promedio nunca más rápido que el arma); el cañón a ≤ 12 studs del cuerpo; punto de mira a ≥ 0.5 studs del cañón. El origen lo pone el servidor (cañón real). Descuenta una bala. |
| `WeaponReload` | C→S | — | Jugador vivo con un arma equipada; no estar recargando; cargador no lleno. Pasado `reloadTime`, si sigue con el arma en la mano, llena el cargador. Guardar el arma cancela la recarga. |
| `WeaponEffect` | S→All | `userId, toolName, origin, endPosition, normal, hitHumanoid` | Lo manda el servidor. El cliente igual chequea los tipos antes de dibujar. |

## Datos que guarda
| DataStore / clave | Estructura | Cuándo se guarda |
|---|---|---|
| — | — | No guarda nada. La munición vive en el atributo `Municion` de la Tool (solo durante la partida). |

## Dependencias
- Usa: la Tool del arma en Studio (nombre igual a una clave o skin de `WeaponConfig`), con `Handle`, los Motor6D a cada pieza (`Mag`, `Bolt`, ...) y los attachments `Muzzle_Att`, `Ejection_Att`, `Aim_Att`, `RightGrip_Att`, `LeftGrip_Att`.
- Lo usan: `Main.server.luau` y `Main.client.luau`.

## Trampas conocidas
- **No editar estos scripts en Studio.** El código vive en `src/` y Rojo pisa lo que esté en Studio.
- Si se renombra la Tool, una pieza o un attachment del `Handle`, el arma deja de funcionar sin dar error (el servidor ignora el disparo; las animaciones buscan los Motor6D por nombre). Una Tool de skin nueva hay que sumarla a `skins` en `WeaponConfig`.
- Los Motor6D del modelo tienen el C0 girado 90°: las animaciones convierten los movimientos de piezas (escritos en ejes del arma) con la rotación de C0.
- El script de cámara de Roblox arranca cada frame desde la cámara anterior: el retroceso de cámara suma solo el **cambio** de la patada (si no, la mira sube para siempre).
- Los brazos del viewmodel solo aparecen con avatares R15 (con R6 se ve solo el arma). La IK de tercera persona también es solo R15.
- `fireSoundId` está vacío: no hay sonido de disparo. No hay contador de balas en pantalla y la reserva es infinita.
- Apuntar es solo visual: el servidor usa la misma dispersión apuntando o no.

## Cómo ajustar la sensación
Todos los valores están en `src/shared/Weapons/ViewmodelConfig.luau`, comentados. Durante un Play en Studio aparecen como atributos de `ReplicatedStorage.AjustesArma` (vista Cliente): se cambian en vivo desde Propiedades; tildar `_Imprimir` escribe los valores en el Output para copiarlos al archivo. `arma.escala` y `brazos.mostrar`/`brazos.escala` se aplican al volver a equipar.

## Cómo testearlo
1. `rojo serve` + Connect en Studio.
2. Play, equipar la AK-47: primera persona con arma y brazos. Disparar (patada y fogonazo desde el cañón que se ve), apuntar con clic derecho, correr (el arma baja y se cruza), R (recarga), V (inspección), pegarse a una pared (el arma se retira).
3. Vaciar el cargador: frena en el tiro 30 y recarga sola.
4. En el Output, solo los dos `[Shared] Sincronización OK` (y el aviso conocido del plugin de Rojo, ver `PROJECT_STATE.md`). Mandar `WeaponFire` con NaN o con un string, o a más velocidad que la cadencia, no tiene que hacer nada.
