## Qué cambia
<!-- Resumen corto de qué hace este PR y por qué. -->

## Sistema que toca
<!-- Ej: Tienda, Inventario. -->
- Sistema(s):
- Revisor: <!-- uno de los otros dos del equipo (docs/OWNERS.md) -->

## Cómo se testeó
<!-- Pasos de playtest (MCP de Studio / Play en Studio) y qué se vio en el Output. -->
1.
2.

## Checklist
- [ ] Pedí review a uno de los otros dos (no se une sin su aprobación)
- [ ] Docs actualizadas (`docs/PROJECT_STATE.md`, `docs/systems/<Sistema>.md`, y `ARCHITECTURE.md` / `DECISIONS.md` si corresponde)
- [ ] Todos los RemoteEvents/RemoteFunctions nuevos o cambiados se validan en el servidor (tipos, rangos, distancia, cooldown, propiedad)
- [ ] `selene src` sin errores
- [ ] `stylua --check src` OK
- [ ] Playtest sin errores en el Output
- [ ] Sin `wait`/`spawn`/`delay`, sin `.rbxl` ni `sourcemap.json` en el diff
