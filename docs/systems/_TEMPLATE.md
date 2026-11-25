# <Sistema>

> Copiar este archivo como `docs/systems/<Sistema>.md`. Mantenerlo corto y al día.

- **Creado por:** @usuario-de-github (no es dueño: cualquiera del equipo puede trabajar acá)
- **Estado:** idea / en progreso / estable
- **Última actualización:** AAAA-MM-DD

## Propósito
Qué hace el sistema y qué NO hace (1–3 líneas).

## Archivos
| Archivo | Lado | Rol |
|---|---|---|
| `src/server/...` | Server | |
| `src/client/...` | Client | |
| `src/shared/...` | Shared | |

## API pública
```lua
-- Funciones/tipos que otros sistemas pueden usar. Todo lo demás es interno.
export type Ejemplo = { id: string, cantidad: number }
function Sistema.start(): ()
```

## RemoteEvents
| Nombre | Dirección | Argumentos | Validación en el servidor |
|---|---|---|---|
| | | | |

(Copiar también a la tabla de `docs/ARCHITECTURE.md`.)

## Datos que guarda
| DataStore / clave | Estructura | Cuándo se guarda |
|---|---|---|
| | | |

## Dependencias
- Usa: …
- Lo usan: …

## Trampas conocidas
- Cosas que ya rompieron o que es fácil hacer mal (exploits, race conditions, orden de carga).

## Cómo testearlo
1. `rojo serve` + Connect en Studio.
2. Play (MCP de Studio) y …
3. Qué tiene que aparecer en el Output / qué no tiene que pasar.
