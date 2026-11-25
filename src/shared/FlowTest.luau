--!strict
-- Módulo temporal para probar el flujo del equipo (rama test/flujo-equipo). No se une a main.

local FlowTest = {}

function FlowTest.suma(a: number, b: number): number
	return a + b
end

function FlowTest.saludo(nombre: string): string
	return "Hola, " .. nombre
end

return FlowTest
