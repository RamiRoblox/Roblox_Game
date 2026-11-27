--!strict
-- Modo ajuste (solo en Studio): muestra los valores de ViewmodelConfig como atributos de
-- ReplicatedStorage.AjustesArma para cambiarlos en vivo durante el Play desde la ventana Propiedades.
-- No toca el archivo: para guardar un ajuste, tildar "_Imprimir" y copiar lo que sale en el Output.
-- En un servidor real (fuera de Studio) no hace nada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ViewmodelConfig = require(ReplicatedStorage.Shared.Weapons.ViewmodelConfig)

local FOLDER_NAME = "AjustesArma"
local PRINT_ATTRIBUTE = "_Imprimir"
local SEPARATOR = "_"

local WeaponTuning = {}

-- Número sin ceros de más: 0.500 → "0.5", 2.000 → "2".
local function formatNumber(value: number): string
	local text = string.gsub(string.format("%.3f", value), "%.?0+$", "")
	if text == "-0" or text == "" then
		return "0"
	end
	return text
end

local function formatValue(value: any): string
	if typeof(value) == "Vector3" then
		return `Vector3.new({formatNumber(value.X)}, {formatNumber(value.Y)}, {formatNumber(value.Z)})`
	elseif typeof(value) == "number" then
		return formatNumber(value)
	end
	return tostring(value)
end

-- Escribe en el Output todos los valores actuales, ordenados, listos para copiar a ViewmodelConfig.
local function printValues(sections: { [string]: { [string]: any } })
	local lines = { "[AjustesArma] Valores actuales (copialos a src/shared/Weapons/ViewmodelConfig.luau):" }
	local sectionNames = {}
	for sectionName in sections do
		table.insert(sectionNames, sectionName)
	end
	table.sort(sectionNames)
	for _, sectionName in sectionNames do
		local keys = {}
		for key in sections[sectionName] do
			table.insert(keys, key)
		end
		table.sort(keys)
		for _, key in keys do
			table.insert(lines, `  {sectionName}.{key} = {formatValue(sections[sectionName][key])}`)
		end
	end
	print(table.concat(lines, "\n"))
end

function WeaponTuning.start(): ()
	if not RunService:IsStudio() then
		return
	end
	-- La tabla de valores es la misma que leen los demás módulos: cambiarla acá se ve en el próximo frame.
	local typedSections: { [string]: { [string]: any } } = ViewmodelConfig.valores :: any

	local folder = Instance.new("Configuration")
	folder.Name = FOLDER_NAME
	for sectionName, section in typedSections do
		for key, value in section do
			folder:SetAttribute(sectionName .. SEPARATOR .. key, value)
		end
	end
	folder:SetAttribute(PRINT_ATTRIBUTE, false)

	folder.AttributeChanged:Connect(function(attribute: string)
		local value = folder:GetAttribute(attribute)
		if attribute == PRINT_ATTRIBUTE then
			if value == true then
				printValues(typedSections)
				folder:SetAttribute(PRINT_ATTRIBUTE, false)
			end
			return
		end
		local sectionName, key = string.match(attribute, "^([^_]+)_(.+)$")
		if not sectionName or not key then
			return
		end
		local section = typedSections[sectionName]
		-- Solo se aceptan cambios del mismo tipo que el valor original (no se puede borrar ni cambiar de tipo).
		if section and section[key] ~= nil and typeof(value) == typeof(section[key]) then
			section[key] = value
		end
	end)

	folder.Parent = ReplicatedStorage
end

return WeaponTuning
