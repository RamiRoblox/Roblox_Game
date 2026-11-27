--!strict
-- Viewmodel (solo cliente): una copia local del arma equipada + los brazos del jugador, pegados a la cámara.
-- Solo lo ve el jugador local. Los demás siguen viendo la Tool real (tercera persona), que acá se esconde solo
-- para este jugador. Es 100 % visual: el disparo lo sigue validando el servidor desde el cañón de la Tool real.
-- Los valores para ajustar están en ReplicatedStorage.Shared.Weapons.ViewmodelConfig.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ViewmodelConfig = require(ReplicatedStorage.Shared.Weapons.ViewmodelConfig)
local WeaponAnimations = require(script.Parent.WeaponAnimations)

local MODEL_NAME = "Viewmodel"
local FIRST_PERSON_DISTANCE = 1 -- si la cámara está más lejos que esto de su foco, no es primera persona
local DEFAULT_MUZZLE = Vector3.new(0, 0, -3) -- por si el arma no tiene Muzzle_Att

-- Un tramo del brazo: una pieza que va de un punto (hombro, codo o muñeca) a otro.
type Bone = {
	part: BasePart,
	startLocal: Vector3, -- dónde empieza el tramo, en coordenadas de la pieza
	endLocal: Vector3, -- dónde termina
	length: number,
	-- Sin estirar (el brazo se estira a lo largo para llegar desde el hombro, fuera de cámara, hasta el arma):
	baseSize: Vector3,
	baseStart: Vector3,
	baseEnd: Vector3,
	stretch: number, -- 1 = largo normal
}

type Arm = {
	side: string, -- "Right" o "Left"
	upper: Bone, -- hombro → codo
	lower: Bone, -- codo → muñeca
	hand: Bone, -- muñeca → punto de agarre
	grip: Attachment, -- attachment del arma que agarra esta mano
	hidden: boolean, -- true mientras el brazo está escondido
}

type SavedProperty = {
	instance: Instance,
	property: string,
	value: any,
}

export type Viewmodel = {
	model: Model,
	handle: BasePart,
	muzzle: Attachment?,
	ejection: Attachment?,
	visible: boolean, -- true mientras se ve el viewmodel (y la Tool real está escondida)
	tool: Tool,
	arms: { Arm },
	skinEffects: { Instance }, -- partículas y luces que trae la skin
	skinEffectsOn: boolean,
	muzzleLocal: Vector3, -- posición del cañón respecto del Handle (para el anti-pared)
	aimLocal: CFrame?, -- la mira (Aim_Att) respecto del Handle; nil si el arma no tiene mira
	motors: { [string]: Motor6D }, -- Motor6D del Handle a cada pieza (Mag, Bolt...), para animarlas
	wallBlend: number, -- 0 = sin pared, 1 = pared pegada (suavizado)
	hiddenTool: { SavedProperty },
	rayParams: RaycastParams,
}

local WeaponViewmodel = {}

local function fromDegrees(angles: Vector3): CFrame
	return CFrame.fromOrientation(math.rad(angles.X), math.rad(angles.Y), math.rad(angles.Z))
end

-- Clone() devuelve nil si el objeto no es Archivable (pasa con partes del personaje): lo habilita un momento.
local function cloneArchivable(source: Instance): Instance
	local wasArchivable = source.Archivable
	source.Archivable = true
	local copy = source:Clone()
	source.Archivable = wasArchivable
	return copy
end

-- Pieza solo visual: anclada (o colgada del Handle anclado), sin colisión, sin sombra, invisible a los raycasts.
local function makeVisualOnly(part: BasePart)
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Massless = true
	part.LocalTransparencyModifier = 0
end

local function isFirstPerson(): boolean
	local camera = Workspace.CurrentCamera
	if not camera then
		return false
	end
	return (camera.Focus.Position - camera.CFrame.Position).Magnitude < FIRST_PERSON_DISTANCE
end

---------------------------------------------------------------------------------------------------------------
-- Brazos

local function attachmentPosition(part: Instance, name: string): Vector3?
	local attachment = part:FindFirstChild(name)
	if attachment and attachment:IsA("Attachment") then
		return attachment.Position
	end
	return nil
end

local function makeBone(source: BasePart, startLocal: Vector3, endLocal: Vector3, scale: number, model: Model): Bone
	local part = cloneArchivable(source) :: BasePart
	-- Fuera constraints, soldaduras, WrapTargets, etc.: solo queda la malla (y su SurfaceAppearance si tiene).
	for _, child in part:GetChildren() do
		if not child:IsA("SurfaceAppearance") then
			child:Destroy()
		end
	end
	part.Size *= scale
	part.Anchored = true
	makeVisualOnly(part)
	part.Parent = model
	local scaledStart, scaledEnd = startLocal * scale, endLocal * scale
	return {
		part = part,
		startLocal = scaledStart,
		endLocal = scaledEnd,
		length = (scaledEnd - scaledStart).Magnitude,
		baseSize = part.Size,
		baseStart = scaledStart,
		baseEnd = scaledEnd,
		stretch = 1,
	}
end

-- Estira (o devuelve a su largo) una pieza del brazo a lo largo de su eje Y, que es el largo del brazo en R15.
local function setStretch(bone: Bone, stretch: number)
	if math.abs(bone.stretch - stretch) < 1e-3 then
		return
	end
	local factor = Vector3.new(1, stretch, 1)
	bone.stretch = stretch
	bone.part.Size = bone.baseSize * factor
	bone.startLocal = bone.baseStart * factor
	bone.endLocal = bone.baseEnd * factor
	bone.length = (bone.endLocal - bone.startLocal).Magnitude
end

-- Copia un brazo R15 del personaje (UpperArm, LowerArm, Hand). Devuelve nil si el avatar no es R15.
local function buildArm(character: Model, side: string, grip: Attachment, scale: number, model: Model): Arm?
	local upper = character:FindFirstChild(side .. "UpperArm")
	local lower = character:FindFirstChild(side .. "LowerArm")
	local hand = character:FindFirstChild(side .. "Hand")
	if not (upper and upper:IsA("BasePart") and lower and lower:IsA("BasePart") and hand and hand:IsA("BasePart")) then
		return nil
	end
	local shoulder = attachmentPosition(upper, side .. "ShoulderRigAttachment")
	local elbowOnUpper = attachmentPosition(upper, side .. "ElbowRigAttachment")
	local elbowOnLower = attachmentPosition(lower, side .. "ElbowRigAttachment")
	local wristOnLower = attachmentPosition(lower, side .. "WristRigAttachment")
	local wristOnHand = attachmentPosition(hand, side .. "WristRigAttachment")
	local gripOnHand = attachmentPosition(hand, side .. "GripAttachment")
	if not (shoulder and elbowOnUpper and elbowOnLower and wristOnLower and wristOnHand and gripOnHand) then
		return nil
	end
	local arm: Arm = {
		side = side,
		upper = makeBone(upper, shoulder, elbowOnUpper, scale, model),
		lower = makeBone(lower, elbowOnLower, wristOnLower, scale, model),
		hand = makeBone(hand, wristOnHand, gripOnHand, scale, model),
		grip = grip,
		hidden = false,
	}
	-- El brazo de arriba (hombro → codo) nunca se ve en primera persona: queda solo para que la ropa se pinte bien.
	arm.upper.part.Transparency = 1
	return arm
end

-- Muestra o esconde un brazo entero (solo para este jugador).
local function setArmHidden(arm: Arm, hidden: boolean)
	if arm.hidden == hidden then
		return
	end
	arm.hidden = hidden
	for _, bone in { arm.lower, arm.hand } do
		bone.part.Transparency = if hidden then 1 else 0
	end
end

-- Pone la pieza para que su tramo vaya de `fromWorld` hacia `toWorld`, con su parte de atrás (+Z, donde está
-- la punta del codo en R15) mirando hacia `bend`.
local function placeBone(bone: Bone, fromWorld: Vector3, toWorld: Vector3, bend: Vector3)
	local direction = toWorld - fromWorld
	if direction.Magnitude < 1e-4 then
		return
	end
	direction = direction.Unit
	local up = bend
	if math.abs(direction:Dot(up)) > 0.999 then
		up = Vector3.yAxis -- caso raro: el tramo apunta justo hacia el codo
	end
	local localFrame = CFrame.lookAt(Vector3.zero, (bone.endLocal - bone.startLocal).Unit, Vector3.zAxis)
	local worldFrame = CFrame.lookAt(Vector3.zero, direction, up)
	bone.part.CFrame = CFrame.new(fromWorld) * worldFrame * localFrame:Inverse() * CFrame.new(-bone.startLocal)
end

-- Mano en `gripPoint` y antebrazo RECTO hacia `direction` (sale de la pantalla), sin codo y con las caras
-- alineadas a `side` (el costado del arma): así el brazo se ve derecho, como en los shooters de referencia.
local function placeForearm(arm: Arm, gripPoint: Vector3, direction: Vector3, side: Vector3, length: number)
	local wrist = gripPoint + direction * arm.hand.length
	placeBone(arm.hand, wrist, gripPoint, side)
	local baseLength = (arm.lower.baseEnd - arm.lower.baseStart).Magnitude
	setStretch(arm.lower, math.max(length / math.max(baseLength, 1e-3), 1))
	placeBone(arm.lower, wrist + direction * arm.lower.length, wrist, side)
end

-- Ropa del avatar en los brazos copiados: necesita un Humanoid en el modelo (sin física ni cartel de nombre).
local function addClothing(character: Model, model: Model)
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.EvaluateStateMachine = false
	humanoid.Parent = model
	for _, className in { "Shirt", "BodyColors" } do
		local item = character:FindFirstChildOfClass(className)
		if item then
			cloneArchivable(item).Parent = model
		end
	end
end

---------------------------------------------------------------------------------------------------------------
-- Tool real y efectos de la skin

local function saveAndSet(list: { SavedProperty }, instance: Instance, property: string, value: any)
	table.insert(list, { instance = instance, property = property, value = (instance :: any)[property] });
	(instance :: any)[property] = value
end

-- Esconde (o vuelve a mostrar) la Tool real SOLO para este jugador. Los demás la siguen viendo.
local function setToolHidden(viewmodel: Viewmodel, hidden: boolean)
	if hidden then
		for _, descendant in viewmodel.tool:GetDescendants() do
			if descendant:IsA("BasePart") then
				saveAndSet(viewmodel.hiddenTool, descendant, "LocalTransparencyModifier", 1)
			elseif
				descendant:IsA("ParticleEmitter")
				or descendant:IsA("Light")
				or descendant:IsA("Beam")
				or descendant:IsA("Trail")
			then
				saveAndSet(viewmodel.hiddenTool, descendant, "Enabled", false)
			end
		end
	else
		for _, saved in viewmodel.hiddenTool do
			if saved.instance.Parent then
				(saved.instance :: any)[saved.property] = saved.value
			end
		end
		table.clear(viewmodel.hiddenTool)
	end
end

local function setSkinEffects(viewmodel: Viewmodel, on: boolean)
	viewmodel.skinEffectsOn = on
	for _, effect in viewmodel.skinEffects do
		(effect :: any).Enabled = on
	end
end

local function setVisible(viewmodel: Viewmodel, visible: boolean)
	if viewmodel.visible == visible then
		return
	end
	viewmodel.visible = visible
	viewmodel.model.Parent = if visible then Workspace.CurrentCamera else nil
	setToolHidden(viewmodel, visible)
end

-- 0 si no hay nada entre la cámara y el cañón (más `margin`). Si hay una pared, crece según cuánto se metería
-- el cañón en ella, hasta 1 cuando se metería `depth` studs o más.
local function getWallTarget(
	viewmodel: Viewmodel,
	from: Vector3,
	muzzle: Vector3,
	margin: number,
	depth: number
): number
	local offset = muzzle - from
	local length = offset.Magnitude + margin
	if length < 1e-3 then
		return 0
	end
	local result = Workspace:Raycast(from, offset.Unit * length, viewmodel.rayParams)
	if not result then
		return 0
	end
	return math.clamp((length - result.Distance) / math.max(depth, 1e-3), 0, 1)
end

---------------------------------------------------------------------------------------------------------------
-- API

-- Arma el viewmodel a partir de la Tool equipada. Empieza invisible: se muestra en el primer update() en
-- primera persona. Devuelve nil si la Tool no tiene Handle.
function WeaponViewmodel.create(character: Model, tool: Tool): Viewmodel?
	local config = ViewmodelConfig.valores

	-- Se clona la Tool entera (no pieza por pieza) para que los Motor6D sigan apuntando a las piezas copiadas.
	local toolCopy = cloneArchivable(tool)
	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	for _, child in toolCopy:GetChildren() do
		child.Parent = model
	end
	toolCopy:Destroy()

	local handle = model:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		model:Destroy()
		return nil
	end

	local skinEffects: { Instance } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			-- Solo el Handle va anclado: las demás piezas cuelgan de él por sus Motor6D (así se pueden animar).
			descendant.Anchored = descendant == handle
			makeVisualOnly(descendant)
		elseif descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		elseif
			descendant:IsA("ParticleEmitter")
			or descendant:IsA("Light")
			or descendant:IsA("Beam")
			or descendant:IsA("Trail")
		then
			table.insert(skinEffects, descendant)
		end
	end
	model.PrimaryPart = handle
	-- Tamaño del arma en primera persona (escala piezas, Motor6D y attachments; los brazos se agregan después).
	if config.arma.escala ~= 1 then
		model:ScaleTo(math.max(config.arma.escala, 0.1))
	end

	local muzzle = handle:FindFirstChild("Muzzle_Att")
	local ejection = handle:FindFirstChild("Ejection_Att")
	local aim = handle:FindFirstChild("Aim_Att")
	local muzzleAttachment = if muzzle and muzzle:IsA("Attachment") then muzzle else nil
	local motors: { [string]: Motor6D } = {}
	for _, child in handle:GetChildren() do
		if child:IsA("Motor6D") then
			motors[child.Name] = child
		end
	end

	local arms: { Arm } = {}
	if config.brazos.mostrar then
		for _, side in { "Right", "Left" } do
			local grip = handle:FindFirstChild(side .. "Grip_Att")
			local arm = if grip and grip:IsA("Attachment")
				then buildArm(character, side, grip, config.brazos.escala, model)
				else nil
			if arm then
				table.insert(arms, arm)
			end
		end
		if #arms > 0 then
			addClothing(character, model)
		end
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character, Workspace.CurrentCamera }
	rayParams.RespectCanCollide = true -- solo cuenta lo que es sólido (paredes), no decoraciones atravesables
	rayParams.IgnoreWater = true

	local viewmodel: Viewmodel = {
		model = model,
		handle = handle,
		muzzle = muzzleAttachment,
		ejection = if ejection and ejection:IsA("Attachment") then ejection else nil,
		visible = false,
		tool = tool,
		arms = arms,
		skinEffects = skinEffects,
		skinEffectsOn = true,
		muzzleLocal = if muzzleAttachment then muzzleAttachment.Position else DEFAULT_MUZZLE,
		aimLocal = if aim and aim:IsA("Attachment") then aim.CFrame else nil,
		motors = motors,
		wallBlend = 0,
		hiddenTool = {},
		rayParams = rayParams,
	}
	setSkinEffects(viewmodel, config.skin.particulas)
	return viewmodel
end

-- Cada frame, después de la cámara: coloca el arma y los brazos respecto de `cameraCFrame`.
-- `motionOffset` es el movimiento extra (balanceo, paso, salto, retroceso) que calcula WeaponMotion.
-- `aimBlend` va de 0 (cadera) a 1 (apuntando con la mira). `pose` es la animación (recarga) de este momento.
-- `runBlend` va de 0 a 1 cuando el jugador corre (el arma baja y se cruza delante del cuerpo).
function WeaponViewmodel.update(
	viewmodel: Viewmodel,
	cameraCFrame: CFrame,
	dt: number,
	motionOffset: CFrame,
	aimBlend: number,
	pose: WeaponAnimations.Pose,
	runBlend: number
): ()
	local firstPerson = isFirstPerson()
	setVisible(viewmodel, firstPerson)
	if not firstPerson then
		return
	end
	local config = ViewmodelConfig.valores
	if config.skin.particulas ~= viewmodel.skinEffectsOn then
		setSkinEffects(viewmodel, config.skin.particulas)
	end

	-- 1) Posición base: de la cadera a la mira según cuánto esté apuntando.
	local base = cameraCFrame * CFrame.new(config.cadera.posicion) * fromDegrees(config.cadera.rotacion)
	local aimLocal = viewmodel.aimLocal
	if aimBlend > 0 and aimLocal then
		-- Pose de mira: el Handle se ubica para que Aim_Att quede justo delante del ojo, mirando al centro.
		local sight = cameraCFrame * CFrame.new(config.apuntar.posicion) * CFrame.new(0, 0, -config.apuntar.distancia)
		base = base:Lerp(sight * aimLocal:Inverse(), aimBlend)
	end
	if runBlend > 0 then
		-- Pose de correr: el arma baja y gira (sobre el punto de agarre) respecto de la cadera.
		local run = CFrame.new(config.correr.posicion) * fromDegrees(config.correr.rotacion)
		base = base * CFrame.new():Lerp(run, runBlend)
	end

	-- 2) Anti-pared: si algo sólido tapa el camino de la cámara al cañón, el arma se retira y se baja.
	local wall = config.antiPared
	local wallTarget =
		getWallTarget(viewmodel, cameraCFrame.Position, base * viewmodel.muzzleLocal, wall.margen, wall.profundidad)
	viewmodel.wallBlend += (wallTarget - viewmodel.wallBlend) * math.min(1, wall.velocidad * dt)
	local blend = viewmodel.wallBlend
	local wallOffset = CFrame.new(0, -wall.bajada * blend, wall.retroceso * blend) * fromDegrees(wall.rotacion * blend)

	-- Mover el Handle anclado mueve todas las piezas unidas a él por Motor6D.
	local handleCFrame = base * motionOffset * pose.weapon * wallOffset
	viewmodel.handle.CFrame = handleCFrame

	-- 3) Piezas animadas (cargador, cerrojo). La pose viene en ejes del arma, pero el Transform de un Motor6D
	-- va en los ejes de su C0 (que en este modelo están girados): se convierte con la rotación de C0.
	for name, motor in viewmodel.motors do
		local offset = pose.parts[name]
		if offset then
			local rotation = motor.C0.Rotation
			motor.Transform = rotation:Inverse() * offset * rotation
		else
			motor.Transform = CFrame.new()
		end
	end

	-- 4) Brazos: cada mano va a su attachment del arma y el antebrazo sale recto, en una dirección fija respecto
	-- del arma (así acompaña al arma en todas las poses: quieto, corriendo, apuntando, recargando).
	local arms = config.brazos
	for _, arm in viewmodel.arms do
		local isRight = arm.side == "Right"
		if isRight and arms.derechoSoloCuandoHaceFalta then
			-- El brazo derecho solo se ve corriendo o cuando tira del cerrojo; disparando o apuntando, no.
			local needed = runBlend > 0.3
			for _, handTarget in pose.hands do
				if handTarget.side == "Right" and handTarget.weight > 0 then
					needed = true
				end
			end
			setArmHidden(arm, not needed)
		else
			setArmHidden(arm, false)
		end
		local handOffset = if isRight
			then arms.manoDerecha
			else arms.manoIzquierda:Lerp(config.apuntar.manoIzquierda, aimBlend)
		local target = arm.grip.WorldCFrame * handOffset
		-- Durante la recarga una mano puede ir a una pieza (la izquierda al cargador, la derecha al cerrojo):
		-- a la bisagra de la pieza, ya movida por la animación, más el corrimiento de la config.
		for _, handTarget in pose.hands do
			local motor = viewmodel.motors[handTarget.part]
			if handTarget.side == arm.side and motor and handTarget.weight > 0 then
				local joint = handleCFrame * motor.C0 * motor.Transform
				local point = joint.Position + handleCFrame:VectorToWorldSpace(handTarget.offset)
				target = target:Lerp(point, handTarget.weight)
			end
		end
		local forearm = if isRight then arms.antebrazoDerecho else arms.antebrazoIzquierdo
		local direction = handleCFrame:VectorToWorldSpace(forearm.Unit)
		placeForearm(arm, target, direction, handleCFrame.RightVector, arms.largoAntebrazo)
	end
end

-- Borra el viewmodel y vuelve a mostrar la Tool real.
function WeaponViewmodel.destroy(viewmodel: Viewmodel): ()
	setToolHidden(viewmodel, false)
	viewmodel.visible = false
	viewmodel.model:Destroy()
end

return WeaponViewmodel
