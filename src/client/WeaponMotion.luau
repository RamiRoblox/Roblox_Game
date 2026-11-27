--!strict
-- Movimiento procedural del viewmodel (solo cliente): balanceo al girar la cámara, paso al caminar o correr,
-- rebote al saltar y al caer, y retroceso al disparar (del arma y de la cámara). Todo con resortes.
-- Los valores están en ViewmodelConfig (balanceo, paso, salto, retroceso, retrocesoCamara).
-- update() devuelve un CFrame de desplazamiento que WeaponViewmodel aplica sobre la posición de cadera;
-- updateCamera() devuelve el giro extra de la cámara por el retroceso.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ViewmodelConfig = require(ReplicatedStorage.Shared.Weapons.ViewmodelConfig)

local MAX_SPRING_STEP = 1 / 240 -- paso máximo de integración de los resortes (estables aunque haya pocos FPS)
local MAX_DT = 0.1 -- después de un tirón de lag no se simula más que esto de golpe
local JUMP_MIN_UP_SPEED = 2 -- despegar del piso subiendo a esta velocidad (o más) cuenta como salto (studs/s)
-- Los empujones de retroceso se multiplican por esto para que el valor de la config sea, más o menos,
-- cuánto se mueve el arma (o la cámara) con un solo disparo.
local IMPULSE_GAIN = 2

type Spring = {
	position: Vector3,
	velocity: Vector3,
}

export type Motion = {
	sway: Spring, -- atraso del balanceo: (cabeceo, giro, 0) en grados
	jump: Spring, -- rebote de salto y caída: (0, altura, 0) en studs
	kickPosition: Spring, -- retroceso del arma: (costado, arriba, atrás) en studs
	kickRotation: Spring, -- retroceso del arma: (cabeceo, giro, ladeo) en grados
	cameraKick: Spring, -- retroceso de la cámara: (cabeceo, giro, 0) en grados
	lastCamera: CFrame?, -- cámara del frame anterior, para medir cuánto giró
	bobPhase: number, -- en qué parte del paso está (radianes)
	bobAmount: number, -- 0 quieto, 1 caminando, más corriendo (suavizado)
	wasGrounded: boolean,
	fallSpeed: number, -- velocidad de caída más alta del salto actual (studs/s)
}

local WeaponMotion = {}

local rng = Random.new()

local function newSpring(): Spring
	return { position = Vector3.zero, velocity = Vector3.zero }
end

-- Resorte amortiguado hacia `target`. `frequency`: qué tan rápido vuelve; `damping`: 1 = sin rebote.
local function stepSpring(spring: Spring, target: Vector3, frequency: number, damping: number, dt: number)
	local omega = 2 * math.pi * math.max(frequency, 0.01)
	local stiffness = omega * omega
	local friction = 2 * math.max(damping, 0) * omega
	local steps = math.max(1, math.ceil(dt / MAX_SPRING_STEP))
	local h = dt / steps
	for _ = 1, steps do
		local acceleration = (target - spring.position) * stiffness - spring.velocity * friction
		spring.velocity += acceleration * h
		spring.position += spring.velocity * h
	end
end

-- Empujón: le da velocidad al resorte para que se mueva más o menos `amount` y después vuelva solo.
local function push(spring: Spring, amount: Vector3, frequency: number)
	spring.velocity += amount * (2 * math.pi * math.max(frequency, 0.01)) * IMPULSE_GAIN
end

-- -1 o 1 al azar.
local function randomSign(): number
	return if rng:NextNumber() < 0.5 then -1 else 1
end

local function clampVector(value: Vector3, limit: number): Vector3
	return Vector3.new(
		math.clamp(value.X, -limit, limit),
		math.clamp(value.Y, -limit, limit),
		math.clamp(value.Z, -limit, limit)
	)
end

local function fromDegrees(angles: Vector3): CFrame
	return CFrame.fromOrientation(math.rad(angles.X), math.rad(angles.Y), math.rad(angles.Z))
end

-- Balanceo: mientras la cámara gira, el arma se atrasa (gira al revés); cuando para, vuelve con el resorte.
local function updateSway(motion: Motion, cameraCFrame: CFrame, dt: number): CFrame
	local config = ViewmodelConfig.valores.balanceo
	local target = Vector3.zero
	local last = motion.lastCamera
	if last and dt > 0 then
		local pitchDelta, yawDelta = last:ToObjectSpace(cameraCFrame):ToEulerAnglesYXZ()
		local turnSpeed = Vector3.new(math.deg(pitchDelta), math.deg(yawDelta), 0) / dt -- grados por segundo
		target = clampVector(-turnSpeed * config.intensidad, config.maximo)
	end
	motion.lastCamera = cameraCFrame
	stepSpring(motion.sway, target, config.frecuencia, config.amortiguacion, dt)

	local lag = motion.sway.position
	-- Además de girar, se corre un poco hacia el lado contrario al giro.
	local offset = Vector3.new(-lag.Y, lag.X, 0) * config.desplazamiento
	return CFrame.new(offset) * fromDegrees(Vector3.new(lag.X, lag.Y, lag.Y * config.inclinacion))
end

-- Paso: un ocho suave (de costado una vez por ciclo, para abajo en cada pisada) que crece con la velocidad.
local function updateBob(motion: Motion, dt: number, horizontalSpeed: number, grounded: boolean): CFrame
	local config = ViewmodelConfig.valores.paso
	local ratio = 0
	if grounded then
		ratio = math.min(horizontalSpeed / math.max(config.velocidadReferencia, 0.01), config.maximo)
		motion.bobPhase += horizontalSpeed * dt * 2 * math.pi / math.max(config.largoCiclo, 0.01)
	end
	motion.bobAmount += (ratio - motion.bobAmount) * math.min(1, config.suavizado * dt)

	local side = math.sin(motion.bobPhase) -- -1 a 1, una vez por ciclo
	local dip = (math.cos(2 * motion.bobPhase) - 1) / 2 -- 0 a -1, una vez por pisada
	local amount = motion.bobAmount
	local position = Vector3.new(side * config.amplitud.X, dip * config.amplitud.Y, side * config.amplitud.Z)
	local rotation = Vector3.new(dip * config.rotacion.X, side * config.rotacion.Y, side * config.rotacion.Z)
	return CFrame.new(position * amount) * fromDegrees(rotation * amount)
end

-- Salto y caída: un empujón al resorte al despegar del piso y otro al aterrizar (más fuerte si caíste rápido).
local function updateJump(motion: Motion, dt: number, verticalSpeed: number, grounded: boolean): CFrame
	local config = ViewmodelConfig.valores.salto
	if motion.wasGrounded and not grounded and verticalSpeed > JUMP_MIN_UP_SPEED then
		motion.jump.velocity += Vector3.new(0, -config.impulsoSalto, 0)
	elseif not motion.wasGrounded and grounded then
		local strength = math.clamp(motion.fallSpeed / math.max(config.caidaReferencia, 0.01), 0, 1.5)
		motion.jump.velocity += Vector3.new(0, -config.impulsoAterrizaje * strength, 0)
		motion.fallSpeed = 0
	end
	if not grounded then
		motion.fallSpeed = math.max(motion.fallSpeed, -verticalSpeed)
	end
	motion.wasGrounded = grounded
	stepSpring(motion.jump, Vector3.zero, config.frecuencia, config.amortiguacion, dt)

	local height = motion.jump.position.Y
	return CFrame.new(0, height, 0) * CFrame.Angles(math.rad(height * config.inclinacion), 0, 0)
end

-- Retroceso del arma: los resortes vuelven solos a cero después de cada empujón de fire().
local function updateKick(motion: Motion, dt: number): CFrame
	local config = ViewmodelConfig.valores.retroceso
	stepSpring(motion.kickPosition, Vector3.zero, config.frecuencia, config.amortiguacion, dt)
	stepSpring(motion.kickRotation, Vector3.zero, config.frecuencia, config.amortiguacion, dt)
	return CFrame.new(motion.kickPosition.position) * fromDegrees(motion.kickRotation.position)
end

function WeaponMotion.new(): Motion
	return {
		sway = newSpring(),
		jump = newSpring(),
		kickPosition = newSpring(),
		kickRotation = newSpring(),
		cameraKick = newSpring(),
		lastCamera = nil,
		bobPhase = 0,
		bobAmount = 0,
		wasGrounded = true,
		fallSpeed = 0,
	}
end

-- Achica un desplazamiento: factor 1 = igual, 0 = nada.
local function scaleOffset(offset: CFrame, factor: number): CFrame
	return CFrame.new():Lerp(offset, factor)
end

local function lerp(from: number, to: number, alpha: number): number
	return from + (to - from) * alpha
end

-- Cada frame: `velocity` es la velocidad del personaje, `grounded` si está pisando algo y `aimBlend` cuánto está
-- apuntando (0 a 1). Devuelve el desplazamiento del arma respecto de su posición base.
function WeaponMotion.update(
	motion: Motion,
	dt: number,
	cameraCFrame: CFrame,
	velocity: Vector3,
	grounded: boolean,
	aimBlend: number
): CFrame
	dt = math.min(dt, MAX_DT)
	local aim = ViewmodelConfig.valores.apuntar
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	-- Al apuntar queda solo una parte del balanceo, del paso y de la patada (según la sección "apuntar").
	return scaleOffset(updateSway(motion, cameraCFrame, dt), lerp(1, aim.balanceo, aimBlend))
		* scaleOffset(updateBob(motion, dt, horizontalSpeed, grounded), lerp(1, aim.paso, aimBlend))
		* updateJump(motion, dt, velocity.Y, grounded)
		* scaleOffset(updateKick(motion, dt), lerp(1, aim.retroceso, aimBlend))
end

-- Un disparo: patea el arma (atrás, arriba y un poco a un costado al azar) y la cámara (arriba y a un costado).
function WeaponMotion.fire(motion: Motion): ()
	local kick = ViewmodelConfig.valores.retroceso
	push(motion.kickPosition, Vector3.new(0, kick.arriba, kick.atras), kick.frecuencia)
	push(
		motion.kickRotation,
		Vector3.new(kick.cabeceo, kick.lateral * randomSign(), kick.ladeo * randomSign()),
		kick.frecuencia
	)
	local camera = ViewmodelConfig.valores.retrocesoCamara
	push(motion.cameraKick, Vector3.new(camera.arriba, camera.lateral * randomSign(), 0), camera.frecuencia)
end

-- Cada frame, después del script de cámara: cuánto hay que girar la cámara por el retroceso.
-- No se acumula en la mira: cuando el resorte vuelve a cero, la cámara vuelve a donde estabas mirando.
function WeaponMotion.updateCamera(motion: Motion, dt: number): CFrame
	local config = ViewmodelConfig.valores.retrocesoCamara
	stepSpring(motion.cameraKick, Vector3.zero, config.frecuencia, config.amortiguacion, math.min(dt, MAX_DT))
	local kick = motion.cameraKick.position
	return CFrame.Angles(math.rad(kick.X), math.rad(kick.Y), 0)
end

return WeaponMotion
