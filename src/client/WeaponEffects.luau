--!strict
-- Efectos visuales y sonoros de las armas (solo cosmético, vive en el cliente).
-- No decide daño ni impactos: dibuja lo que el servidor ya resolvió.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local WeaponConfig = require(game:GetService("ReplicatedStorage").Shared.Weapons.WeaponConfig)

local FLASH_NAME = "WeaponMuzzleFlash"
local LIGHT_NAME = "WeaponMuzzleLight"
local SOUND_NAME = "WeaponFireSound"

local MIN_TRACER_TIME = 0.03
local TRACER_LENGTH = 3
local CASING_LIFETIME = 0.7

local WeaponEffects = {}

local effectsFolder: Folder? = nil

local function getEffectsFolder(): Folder
	if effectsFolder and effectsFolder.Parent then
		return effectsFolder
	end
	local folder = Instance.new("Folder")
	folder.Name = "WeaponEffects"
	folder.Parent = Workspace
	effectsFolder = folder
	return folder
end

-- Attachment suelto en el mundo (colgado de Terrain) para efectos que no siguen a ningún arma.
local function makeWorldAttachment(position: Vector3, lifetime: number): Attachment
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = Workspace.Terrain
	Debris:AddItem(attachment, lifetime)
	return attachment
end

local function makeFlashEmitter(): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = FLASH_NAME
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.05, 0.1)
	emitter.Speed = NumberRange.new(6, 14)
	emitter.SpreadAngle = Vector2.new(18, 18)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 230, 140), Color3.fromRGB(255, 130, 40))
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.EmissionDirection = Enum.NormalId.Front
	return emitter
end

local function flashAt(attachment: Attachment)
	local emitter = attachment:FindFirstChild(FLASH_NAME)
	if not emitter or not emitter:IsA("ParticleEmitter") then
		emitter = makeFlashEmitter()
		emitter.Parent = attachment
	end
	(emitter :: ParticleEmitter):Emit(6)

	local light = attachment:FindFirstChild(LIGHT_NAME)
	if not light or not light:IsA("PointLight") then
		local newLight = Instance.new("PointLight")
		newLight.Name = LIGHT_NAME
		newLight.Color = Color3.fromRGB(255, 190, 110)
		newLight.Brightness = 3
		newLight.Range = 12
		newLight.Enabled = false
		newLight.Parent = attachment
		light = newLight
	end
	local pointLight = light :: PointLight
	pointLight.Enabled = true
	task.delay(0.05, function()
		if pointLight.Parent then
			pointLight.Enabled = false
		end
	end)
end

local function playFireSound(attachment: Attachment, soundId: string)
	if soundId == "" then
		return
	end
	local sound = attachment:FindFirstChild(SOUND_NAME)
	if not sound or not sound:IsA("Sound") then
		local newSound = Instance.new("Sound")
		newSound.Name = SOUND_NAME
		newSound.SoundId = soundId
		newSound.RollOffMaxDistance = 300
		newSound.RollOffMinDistance = 15
		newSound.Volume = 0.8
		newSound.Parent = attachment
		sound = newSound
	end
	local fireSound = sound :: Sound
	fireSound.PlaybackSpeed = 0.95 + math.random() * 0.1
	fireSound.TimePosition = 0
	fireSound:Play()
end

-- Cartucho que sale despedido por la ventana de eyección (dura menos de un segundo).
local function ejectCasing(ejection: Attachment)
	local casing = Instance.new("Part")
	casing.Size = Vector3.new(0.08, 0.08, 0.25)
	casing.Color = Color3.fromRGB(205, 160, 60)
	casing.Material = Enum.Material.Metal
	casing.CanCollide = false
	casing.CanTouch = false
	casing.CanQuery = false
	casing.CastShadow = false
	casing.CFrame = ejection.WorldCFrame
	casing.Parent = getEffectsFolder()
	local side = ejection.WorldCFrame.RightVector
	casing.AssemblyLinearVelocity = side * (9 + math.random() * 3) + Vector3.new(0, 7 + math.random() * 2, 0)
	casing.AssemblyAngularVelocity = Vector3.new(math.random() * 30, math.random() * 30, math.random() * 30)
	Debris:AddItem(casing, CASING_LIFETIME)
end

-- Busca el arma (Tool) con ese nombre en el personaje del tirador.
local function findTool(shooter: Model?, toolName: string): Tool?
	if not shooter then
		return nil
	end
	local tool = shooter:FindFirstChild(toolName)
	if tool and tool:IsA("Tool") then
		return tool
	end
	return nil
end

-- Fogonazo + luz + sonido + cartucho en el cañón. Se usa al disparar (el tirador lo ve al instante)
-- y cuando otro jugador dispara. `origin` es el respaldo si no se encuentra el arma.
function WeaponEffects.playMuzzle(shooter: Model?, toolName: string, origin: Vector3): ()
	local stats = WeaponConfig.get(toolName)
	if not stats then
		return
	end
	local tool = findTool(shooter, toolName)
	local handle = if tool then tool:FindFirstChild("Handle") else nil
	local muzzle = if handle then handle:FindFirstChild("Muzzle_Att") else nil
	local ejection = if handle then handle:FindFirstChild("Ejection_Att") else nil

	if muzzle and muzzle:IsA("Attachment") then
		flashAt(muzzle)
		playFireSound(muzzle, stats.fireSoundId)
	else
		local fallback = makeWorldAttachment(origin, 1)
		flashAt(fallback)
		playFireSound(fallback, stats.fireSoundId)
	end
	if ejection and ejection:IsA("Attachment") then
		ejectCasing(ejection)
	end
end

local function impactAt(position: Vector3, normal: Vector3, hitHumanoid: boolean)
	local attachment = makeWorldAttachment(position, 1)
	attachment.WorldCFrame = CFrame.lookAt(position, position + normal)

	local sparks = Instance.new("ParticleEmitter")
	sparks.Rate = 0
	sparks.Lifetime = NumberRange.new(0.15, 0.35)
	sparks.Speed = NumberRange.new(8, 18)
	sparks.SpreadAngle = Vector2.new(35, 35)
	sparks.Acceleration = Vector3.new(0, -30, 0)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.EmissionDirection = Enum.NormalId.Front
	if hitHumanoid then
		sparks.Color = ColorSequence.new(Color3.fromRGB(210, 40, 40))
		sparks.LightEmission = 0.2
	else
		sparks.Color = ColorSequence.new(Color3.fromRGB(255, 220, 130), Color3.fromRGB(255, 120, 40))
	end
	sparks.Parent = attachment
	sparks:Emit(if hitHumanoid then 12 else 8)
end

-- Bala trazadora: un destello que viaja del cañón al punto de impacto y, al llegar, el impacto.
function WeaponEffects.playBullet(
	origin: Vector3,
	endPosition: Vector3,
	normal: Vector3,
	hitHumanoid: boolean,
	speed: number
): ()
	local offset = endPosition - origin
	local distance = offset.Magnitude
	if distance < 0.1 then
		impactAt(endPosition, normal, hitHumanoid)
		return
	end
	local direction = offset.Unit
	local length = math.min(TRACER_LENGTH, distance)

	local tracer = Instance.new("Part")
	tracer.Size = Vector3.new(0.06, 0.06, length)
	tracer.Color = Color3.fromRGB(255, 215, 120)
	tracer.Material = Enum.Material.Neon
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanTouch = false
	tracer.CanQuery = false
	tracer.CastShadow = false
	tracer.CFrame = CFrame.lookAt(origin, endPosition) * CFrame.new(0, 0, -length / 2)
	tracer.Parent = getEffectsFolder()

	-- El centro viaja hasta quedar justo antes del impacto.
	local finalCenter = endPosition - direction * (length / 2)
	local travelTime = math.max(distance / math.max(speed, 1), MIN_TRACER_TIME)
	local tween = TweenService:Create(
		tracer,
		TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.lookAt(finalCenter, finalCenter + direction) }
	)
	tween.Completed:Once(function()
		tracer:Destroy()
		impactAt(endPosition, normal, hitHumanoid)
	end)
	tween:Play()
end

return WeaponEffects
