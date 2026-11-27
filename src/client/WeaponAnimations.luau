--!strict
-- Animaciones del viewmodel hechas por código (solo cliente): la recarga y la inspección.
-- No usa archivos de animación: cada momento se calcula con los valores de ViewmodelConfig (secciones "recarga"
-- e "inspeccion"), así se ajustan igual que el resto. update() devuelve una Pose que WeaponViewmodel aplica.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ViewmodelConfig = require(ReplicatedStorage.Shared.Weapons.ViewmodelConfig)

-- A qué pieza del arma va una mano, y cuánto (0 = se queda en su agarre de siempre, 1 = en la pieza).
export type HandTarget = {
	side: string, -- "Left" o "Right"
	part: string, -- nombre del Motor6D de la pieza (por ejemplo "Mag")
	weight: number,
	offset: Vector3, -- desde la bisagra de la pieza, en ejes del arma
}

export type Pose = {
	weapon: CFrame, -- desplazamiento extra del arma entera
	parts: { [string]: CFrame }, -- movimiento de cada pieza (por nombre de su Motor6D), en ejes del arma
	hands: { HandTarget },
}

export type Animator = {
	action: string?, -- animación que se está reproduciendo ("Reload", "Inspect") o nil
	startTime: number,
	duration: number,
	lastWeapon: CFrame, -- desplazamiento del arma del último frame
	fadeFrom: CFrame, -- desde dónde se hace la transición suave al cortar o cambiar de animación
	fadeStart: number,
}

local IDLE_POSE: Pose = { weapon = CFrame.new(), parts = {}, hands = {} }
local FADE_TIME = 0.15 -- segundos de transición al cortar una animación (por ejemplo, disparar inspeccionando)

local WeaponAnimations = {}

local function smoothstep(x: number): number
	return x * x * (3 - 2 * x)
end

-- 0 antes de `from`, 1 después de `to` y una curva suave en el medio.
local function phase(t: number, from: number, to: number): number
	if to <= from then
		return if t >= to then 1 else 0
	end
	return smoothstep(math.clamp((t - from) / (to - from), 0, 1))
end

local function fromDegrees(angles: Vector3): CFrame
	return CFrame.fromOrientation(math.rad(angles.X), math.rad(angles.Y), math.rad(angles.Z))
end

-- Recarga en el momento `t` (0 a 1).
local function reloadPose(t: number): Pose
	local c = ViewmodelConfig.valores.recarga

	-- El arma entera se inclina al empezar y vuelve al final; al meter el cargador da un golpecito hacia arriba.
	local tilt = phase(t, 0, c.entrada) * (1 - phase(t, 1 - c.salida, 1))
	local bump = phase(t, c.cargadorDentro, c.cargadorDentro + 0.04)
		* (1 - phase(t, c.cargadorDentro + 0.04, c.cargadorDentro + 0.14))
	local weapon = CFrame.new(c.desplazamiento * tilt)
		* fromDegrees(c.inclinacion * tilt + Vector3.new(c.golpe * bump, 0, 0))

	-- El cargador sale, espera afuera y vuelve a entrar.
	local mag = phase(t, c.cargadorSale, c.cargadorFuera) * (1 - phase(t, c.cargadorEntra, c.cargadorDentro))
	-- El cerrojo va hacia atrás y vuelve de golpe al soltarlo.
	local bolt = phase(t, c.cerrojoTira, c.cerrojoAtras) * (1 - phase(t, c.cerrojoSuelta, c.cerrojoSuelta + 0.03))

	-- La mano izquierda saca y mete el cargador. Después la derecha suelta la empuñadura y tira de la manija del
	-- cerrojo, que en el AK está del lado derecho (mientras, la izquierda sostiene el guardamanos).
	local handOnMag = phase(t, c.cargadorSale - 0.08, c.cargadorSale)
		* (1 - phase(t, c.cargadorDentro, c.cargadorDentro + 0.06))
	local handOnBolt = phase(t, c.cerrojoTira - 0.08, c.cerrojoTira)
		* (1 - phase(t, c.cerrojoSuelta, c.cerrojoSuelta + 0.1))

	return {
		weapon = weapon,
		parts = {
			Mag = CFrame.new(c.cargadorRecorrido * mag) * fromDegrees(c.cargadorGiro * mag),
			Bolt = CFrame.new(c.cerrojoRecorrido * bolt),
		},
		hands = {
			{ side = "Left", part = "Mag", weight = handOnMag, offset = c.manoCargador },
			{ side = "Right", part = "Bolt", weight = handOnBolt, offset = c.manoCerrojo },
		},
	}
end

-- Inspección en el momento `t` (0 a 1): el arma se acerca, muestra un costado, gira al otro y vuelve.
local function inspectPose(t: number): Pose
	local c = ViewmodelConfig.valores.inspeccion
	local inOut = phase(t, 0, c.entrada) * (1 - phase(t, 1 - c.salida, 1))
	local turn = phase(t, c.cambio, c.cambio + c.cambioDuracion)
	local rotation = fromDegrees(c.primerGiro):Lerp(fromDegrees(c.segundoGiro), turn)
	return {
		weapon = CFrame.new():Lerp(CFrame.new(c.desplazamiento) * rotation, inOut),
		parts = {},
		hands = {},
	}
end

function WeaponAnimations.new(): Animator
	return {
		action = nil,
		startTime = 0,
		duration = 1,
		lastWeapon = CFrame.new(),
		fadeFrom = CFrame.new(),
		fadeStart = -math.huge,
	}
end

-- Arranca la transición suave desde donde está el arma ahora.
local function startFade(animator: Animator)
	animator.fadeFrom = animator.lastWeapon
	animator.fadeStart = os.clock()
end

-- Empieza una animación ("Reload" o "Inspect") que dura `duration` segundos.
function WeaponAnimations.play(animator: Animator, action: string, duration: number): ()
	startFade(animator)
	animator.action = action
	animator.startTime = os.clock()
	animator.duration = math.max(duration, 0.01)
end

-- Corta la animación; el arma vuelve a su lugar en FADE_TIME segundos.
function WeaponAnimations.stop(animator: Animator): ()
	if animator.action then
		startFade(animator)
	end
	animator.action = nil
end

-- true si se está reproduciendo `action` (o cualquier animación si `action` es nil).
function WeaponAnimations.isPlaying(animator: Animator, action: string?): boolean
	if animator.action == nil or (action ~= nil and animator.action ~= action) then
		return false
	end
	return os.clock() - animator.startTime < animator.duration
end

-- Cada frame: la pose del momento actual de la animación (o la pose quieta si no hay ninguna).
function WeaponAnimations.update(animator: Animator): Pose
	local pose = IDLE_POSE
	if WeaponAnimations.isPlaying(animator) then
		local t = (os.clock() - animator.startTime) / animator.duration
		if animator.action == "Reload" then
			pose = reloadPose(t)
		elseif animator.action == "Inspect" then
			pose = inspectPose(t)
		end
	else
		animator.action = nil
	end

	-- Transición suave después de cortar o cambiar de animación (si no, el arma saltaría de golpe).
	local fade = (os.clock() - animator.fadeStart) / FADE_TIME
	if fade < 1 then
		pose = {
			weapon = animator.fadeFrom:Lerp(pose.weapon, smoothstep(math.clamp(fade, 0, 1))),
			parts = pose.parts,
			hands = pose.hands,
		}
	end
	animator.lastWeapon = pose.weapon
	return pose
end

return WeaponAnimations
