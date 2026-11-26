# Armas

- **Creado por:** código escrito directo en Studio; pasado a Git por @vFrangi (no es dueño: cualquiera del equipo puede trabajar acá)
- **Estado:** en progreso (funciona en playtest; falta el sonido del disparo)
- **Última actualización:** 2026-11-25

## Propósito
Disparo de las armas (por ahora la AK-47): el cliente apunta y pide disparar, el servidor valida, hace el raycast y aplica el daño, y todos los clientes dibujan los efectos (fogonazo, bala trazadora, cartucho, impacto). También pone la mano izquierda en el guardamanos con IK (R15).
NO maneja munición, recarga, compra ni skins.

## Archivos
| Archivo | Lado | Rol |
|---|---|---|
| `src/server/WeaponService.luau` | Server | Valida el disparo, raycast, daño (con headshot y sin fuego amigo), IK de la mano izquierda. |
| `src/client/WeaponController.luau` | Client | Input, punto de mira, cadencia del lado cliente, el personaje mira hacia donde apunta, retroceso de cámara. |
| `src/client/WeaponEffects.luau` | Client | Solo cosmético: fogonazo, luz, sonido, cartucho, bala trazadora e impacto. |
| `src/shared/Weapons/WeaponConfig.luau` | Shared | Stats de cada arma (clave = `Name` de la Tool) y nombres de los RemoteEvents. |

Fuera de Git (viven en Studio): la Tool `StarterPack.AK-47` y los modelos de `ReplicatedStorage.Armas` (AK47, AK47_dorada, AK47_hielo).

## API pública
```lua
-- WeaponConfig (shared)
export type WeaponStats = {
	damage: number, headshotMultiplier: number, fireRate: number, range: number,
	spreadDegrees: number, tracerSpeed: number, recoilPitchDegrees: number, fireSoundId: string,
}
function WeaponConfig.get(weaponName: string): WeaponStats?

function WeaponService.start(): ()     -- desde Main.server.luau
function WeaponController.start(): ()  -- desde Main.client.luau
function WeaponEffects.playMuzzle(shooter: Model?, toolName: string, origin: Vector3): ()
function WeaponEffects.playBullet(origin: Vector3, endPosition: Vector3, normal: Vector3, hitHumanoid: boolean, speed: number): ()
```

## RemoteEvents
Los crea `WeaponService.start()` dentro de `ReplicatedStorage.Remotes`.

| Nombre | Dirección | Argumentos | Validación en el servidor |
|---|---|---|---|
| `WeaponFire` | C→S | `aimPoint: Vector3` | `typeof` Vector3; descarta NaN/inf y coordenadas > 1e6; jugador vivo con una Tool equipada que sea un arma de `WeaponConfig`, con `Handle.Muzzle_Att`; cadencia por jugador (60/fireRate × 0.85); el cañón a ≤ 12 studs del cuerpo; punto de mira a ≥ 0.5 studs del cañón. El origen del disparo lo pone el servidor (cañón real), no el cliente. |
| `WeaponEffect` | S→All | `userId, toolName, origin, endPosition, normal, hitHumanoid` | Lo manda el servidor. El cliente igual chequea los tipos antes de dibujar. |

## Datos que guarda
| DataStore / clave | Estructura | Cuándo se guarda |
|---|---|---|
| — | — | No guarda nada. |

## Dependencias
- Usa: la Tool del arma en Studio (nombre igual a la clave de `WeaponConfig`, con `Handle` y los attachments `Muzzle_Att`, `Ejection_Att`, `LeftGrip_Att`).
- Lo usan: `Main.server.luau` y `Main.client.luau`.

## Trampas conocidas
- **No editar estos scripts en Studio.** Este código estuvo un tiempo solo en Studio; ahora vive en `src/` y Rojo pisa lo que esté en Studio.
- Si se renombra la Tool o un attachment del `Handle`, el arma deja de disparar sin dar error (el servidor ignora el disparo). Renombrar también en `WeaponConfig`.
- La IK de la mano izquierda solo funciona con avatares R15.
- `fireSoundId` está vacío: por ahora no hay sonido de disparo.

## Cómo testearlo
1. `rojo serve` + Connect en Studio.
2. Play (MCP de Studio), equipar la AK-47 y disparar a una pared y a un Humanoid.
3. En el Output tienen que aparecer los dos mensajes `[Shared] Sincronización OK` y ningún error. Mandar `WeaponFire` con NaN o con un string no tiene que hacer nada.
