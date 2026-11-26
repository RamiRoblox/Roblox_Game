# Arquitectura

> Mantener al día: si agregás un sistema o un RemoteEvent, actualizá este archivo en el mismo PR.

## Mapa de sistemas
| Sistema | Server | Client | Shared | Doc |
|---|---|---|---|---|
| _(ejemplo)_ Hello | `src/server/Main.server.luau` | `src/client/Main.client.luau` | `src/shared/Hello.luau` | — |
| Armas | `src/server/WeaponService.luau` | `src/client/WeaponController.luau`, `src/client/WeaponEffects.luau` | `src/shared/Weapons/WeaponConfig.luau` | [Armas](systems/Armas.md) |

<!-- Al crear un sistema con /nuevo-sistema se agrega una fila acá. -->

## Convenciones
- Cada sistema es un ModuleScript con API tipada:
  - Server: `src/server/<Sistema>/init.luau` (o `src/server/<Sistema>Service.luau`), con `start()` llamado desde `Main.server.luau`.
  - Client: `src/client/<Sistema>Controller.luau`, con `start()` llamado desde `Main.client.luau`.
  - Shared: tipos, constantes y configuración en `src/shared/<Sistema>/`.
- Los RemoteEvents se crean **en el servidor** dentro de `ReplicatedStorage.Remotes` (Folder) y el cliente los espera con `WaitForChild`.
- Un sistema no hace `require` de los internos de otro: usa solo su API pública.

## RemoteEvents / RemoteFunctions
| Nombre | Tipo | Dirección | Argumentos | Validación en el servidor | Sistema |
|---|---|---|---|---|---|
| `WeaponFire` | RemoteEvent | C→S | `aimPoint: Vector3` | Tipo, NaN/inf, vivo con un arma equipada, cadencia por jugador, cañón cerca del cuerpo; el origen lo pone el servidor | Armas |
| `WeaponEffect` | RemoteEvent | S→All | `userId, toolName, origin, endPosition, normal, hitHumanoid` | Lo manda el servidor (el cliente chequea tipos) | Armas |

Dirección: `C→S` (cliente pide), `S→C` (servidor avisa), `S→All` (broadcast).
Columna "Validación": qué chequea el servidor (tipos, rangos, distancia, cooldown, si tiene el ítem/plata). **Si está vacía, el remote no se une.**

## Flujo cliente ↔ servidor
```
Jugador (input)
   │
   ▼
Client Controller ── RemoteEvent (C→S, solo intención: "quiero comprar X") ──▶ Server Service
                                                                                  │ 1. validar (tipos, rangos, distancia, cooldown)
                                                                                  │ 2. verificar estado real (plata, inventario)
                                                                                  │ 3. aplicar cambio (fuente de verdad)
                                                                                  │ 4. guardar (DataStore con pcall)
Client Controller ◀── RemoteEvent (S→C, resultado/estado nuevo) ◀────────────────┘
   │
   ▼
UI se actualiza (el cliente nunca decide el resultado)
```

## Datos persistentes
| DataStore | Clave | Qué guarda | Sistema |
|---|---|---|---|
| — | — | — | — |
