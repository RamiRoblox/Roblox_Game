--!strict
-- Módulo de ejemplo: si server y client imprimen su mensaje, Rojo está sincronizando bien.
-- Se puede borrar cuando exista el primer sistema real.

local Hello = {}

function Hello.greet(context: string): string
	return `[Shared] Sincronización OK desde {context}`
end

return Hello
