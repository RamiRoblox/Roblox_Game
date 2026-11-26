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
	recoilPitchDegrees: number, -- patada de cámara por disparo (grados)
	fireSoundId: string, -- "rbxassetid://..." (vacío = sin sonido)
}

local WeaponConfig = {}

WeaponConfig.remotesFolderName = "Remotes"
WeaponConfig.fireRemoteName = "WeaponFire" -- C→S: el cliente pide disparar
WeaponConfig.effectRemoteName = "WeaponEffect" -- S→All: el servidor avisa el resultado del disparo

local weapons: { [string]: WeaponStats } = {
	["AK-47"] = {
		damage = 25,
		headshotMultiplier = 2,
		fireRate = 600,
		range = 400,
		spreadDegrees = 1.2,
		tracerSpeed = 900,
		recoilPitchDegrees = 0.6,
		fireSoundId = "",
	},
}

-- Devuelve las stats del arma, o nil si el nombre no es un arma conocida.
function WeaponConfig.get(weaponName: string): WeaponStats?
	return weapons[weaponName]
end

return WeaponConfig
