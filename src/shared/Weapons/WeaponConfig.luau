--!strict
-- Configuración compartida de las armas (la lee el servidor para validar/dañar y el cliente para los efectos).
-- La clave de `weapons` es el Name de la Tool (p. ej. "AK-47").

export type WeaponStats = {
	damage: number, -- daño por bala al cuerpo
	headshotMultiplier: number, -- multiplicador si pega en "Head"
	fireRate: number, -- disparos por minuto
	range: number, -- alcance máximo de la bala (studs)
	spreadDegrees: number, -- dispersión máxima (grados, cono)
	tracerSpeed: number, -- velocidad visual de la bala trazadora (studs/s)
	magazineSize: number, -- balas por cargador
	reloadTime: number, -- segundos que tarda la recarga (el servidor la cuenta; la animación dura lo mismo)
	-- (el retroceso del arma y de la cámara se ajusta en ViewmodelConfig)
	fireSoundId: string, -- "rbxassetid://..." (vacío = sin sonido)
}

local WeaponConfig = {}

WeaponConfig.remotesFolderName = "Remotes"
WeaponConfig.fireRemoteName = "WeaponFire" -- C→S: el cliente pide disparar
WeaponConfig.reloadRemoteName = "WeaponReload" -- C→S: el cliente pide recargar
WeaponConfig.effectRemoteName = "WeaponEffect" -- S→All: el servidor avisa el resultado del disparo

-- Atributos que el SERVIDOR pone en la Tool (el cliente solo los lee; si el cliente los cambia, no se replica).
WeaponConfig.ammoAttribute = "Municion" -- balas que quedan en el cargador
WeaponConfig.reloadingAttribute = "Recargando" -- true mientras dura la recarga

local weapons: { [string]: WeaponStats } = {
	["AK-47"] = {
		damage = 25,
		headshotMultiplier = 2,
		fireRate = 600,
		range = 400,
		spreadDegrees = 1.2,
		tracerSpeed = 900,
		magazineSize = 30,
		reloadTime = 2.2,
		fireSoundId = "",
	},
}

-- Skins: Tools con otro nombre que usan las mismas stats que un arma base (nombre de la Tool → arma base).
local skins: { [string]: string } = {
	["AK-47 Glaciar"] = "AK-47",
}

-- Devuelve las stats del arma (o de su arma base si es una skin), o nil si el nombre no es un arma conocida.
function WeaponConfig.get(weaponName: string): WeaponStats?
	return weapons[skins[weaponName] or weaponName]
end

return WeaponConfig
