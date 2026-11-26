--!strict
-- Sistema de armas (servidor): valida el disparo, hace el raycast, aplica el daño
-- y avisa a todos los clientes para que dibujen los efectos.
-- El cliente solo manda "quiero disparar hacia este punto"; el origen sale del cañón real.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WeaponConfig = require(ReplicatedStorage.Shared.Weapons.WeaponConfig)

local MAX_COORD = 1e6 -- cualquier coordenada más grande (o NaN/inf) se descarta
local MIN_AIM_DISTANCE = 0.5 -- punto de mira demasiado pegado al cañón
local MAX_MUZZLE_DISTANCE = 12 -- el cañón no puede estar lejos del cuerpo del jugador
local FIRE_TOLERANCE = 0.85 -- margen por jitter de red sobre el intervalo entre disparos

local HAND_IK_NAME = "WeaponLeftHandIK"
local HAND_POLE_NAME = "WeaponLeftHandPole"

local WeaponService = {}

local effectRemote: RemoteEvent? = nil
local lastFireTime: { [Player]: number } = {}
local rng = Random.new()
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function getOrCreate(parent: Instance, className: string, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = parent
	return created
end

local function isValidPoint(point: Vector3): boolean
	-- Las comparaciones con NaN dan false, así que esto también descarta NaN e infinitos.
	return math.abs(point.X) < MAX_COORD and math.abs(point.Y) < MAX_COORD and math.abs(point.Z) < MAX_COORD
end

-- Desvía la dirección dentro de un cono de `spreadDegrees`.
local function applySpread(direction: Vector3, spreadDegrees: number): Vector3
	if spreadDegrees <= 0 then
		return direction
	end
	local roll = rng:NextNumber(0, 2 * math.pi)
	local offset = math.rad(rng:NextNumber(0, spreadDegrees))
	local frame = CFrame.lookAt(Vector3.zero, direction) * CFrame.Angles(0, 0, roll) * CFrame.Angles(offset, 0, 0)
	return frame.LookVector
end

local function findHumanoid(instance: Instance): Humanoid?
	local model: Instance? = instance:FindFirstAncestorOfClass("Model")
	while model do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return humanoid
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function canDamage(shooter: Player, victim: Humanoid): boolean
	local victimModel = victim.Parent
	local victimPlayer = if victimModel and victimModel:IsA("Model")
		then Players:GetPlayerFromCharacter(victimModel)
		else nil
	if victimPlayer and shooter.Team ~= nil and victimPlayer.Team == shooter.Team then
		return false -- sin fuego amigo
	end
	return true
end

local function onFire(player: Player, aimPoint: any)
	-- 1) Validar el argumento
	if typeof(aimPoint) ~= "Vector3" then
		return
	end
	local target = aimPoint :: Vector3
	if not isValidPoint(target) then
		return
	end

	-- 2) Validar el estado real del jugador (vivo, con el arma equipada)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		return
	end
	local stats = WeaponConfig.get(tool.Name)
	local handle = tool:FindFirstChild("Handle")
	if not stats or not handle then
		return
	end
	local muzzle = handle:FindFirstChild("Muzzle_Att")
	if not muzzle or not muzzle:IsA("Attachment") then
		return
	end

	-- 3) Cadencia: el servidor manda, no el cliente
	local now = os.clock()
	local interval = 60 / stats.fireRate
	if now - (lastFireTime[player] or 0) < interval * FIRE_TOLERANCE then
		return
	end
	lastFireTime[player] = now

	-- 4) El origen es el cañón real, que tiene que estar cerca del cuerpo
	local origin = muzzle.WorldPosition
	if (origin - root.Position).Magnitude > MAX_MUZZLE_DISTANCE then
		return
	end
	local toTarget = target - origin
	if toTarget.Magnitude < MIN_AIM_DISTANCE then
		return
	end
	local direction = applySpread(toTarget.Unit, stats.spreadDegrees)

	-- 5) Raycast. Primero del cuerpo al cañón (si hay una pared en el medio, la bala pega ahí).
	rayParams.FilterDescendantsInstances = { character }
	local result = Workspace:Raycast(root.Position, origin - root.Position, rayParams)
	if not result then
		result = Workspace:Raycast(origin, direction * stats.range, rayParams)
	end

	local endPosition = origin + direction * stats.range
	local normal = -direction
	local hitHumanoid = false
	if result then
		endPosition = result.Position
		normal = result.Normal
		local victim = findHumanoid(result.Instance)
		if victim and victim ~= humanoid and victim.Health > 0 then
			hitHumanoid = true
			if canDamage(player, victim) then
				local damage = stats.damage
				if result.Instance.Name == "Head" then
					damage *= stats.headshotMultiplier
				end
				victim:TakeDamage(damage)
			end
		end
	end

	-- 6) Avisar a todos para que dibujen la bala y los efectos
	if effectRemote then
		effectRemote:FireAllClients(player.UserId, tool.Name, origin, endPosition, normal, hitHumanoid)
	end
end

-- La mano izquierda agarra el guardamanos con IK (solo R15).
local function attachLeftHandIK(character: Model, tool: Tool)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local upperArm = character:FindFirstChild("LeftUpperArm")
	local hand = character:FindFirstChild("LeftHand")
	local torso = character:FindFirstChild("UpperTorso")
	local handle = tool:FindFirstChild("Handle")
	local grip = if handle then handle:FindFirstChild("LeftGrip_Att") else nil
	if not humanoid or not upperArm or not hand or not torso or not grip then
		return
	end

	local pole = Instance.new("Attachment")
	pole.Name = HAND_POLE_NAME
	pole.Position = Vector3.new(-1.5, -1, 1) -- el codo se dobla hacia afuera y atrás
	pole.Parent = torso

	local ik = Instance.new("IKControl")
	ik.Name = HAND_IK_NAME
	ik.Type = Enum.IKControlType.Position
	ik.ChainRoot = upperArm
	ik.EndEffector = hand
	ik.Target = grip
	ik.Pole = pole
	ik.SmoothTime = 0.05
	ik.Parent = humanoid
end

local function detachLeftHandIK(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local ik = if humanoid then humanoid:FindFirstChild(HAND_IK_NAME) else nil
	if ik then
		ik:Destroy()
	end
	local torso = character:FindFirstChild("UpperTorso")
	local pole = if torso then torso:FindFirstChild(HAND_POLE_NAME) else nil
	if pole then
		pole:Destroy()
	end
end

-- Las conexiones cuelgan del personaje: se limpian solas cuando el personaje se destruye al respawnear.
local function onCharacterAdded(character: Model)
	character.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Tool") and WeaponConfig.get(child.Name) then
			attachLeftHandIK(character, child)
		end
	end)
	character.ChildRemoved:Connect(function(child: Instance)
		if child:IsA("Tool") and WeaponConfig.get(child.Name) then
			detachLeftHandIK(character)
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

function WeaponService.start(): ()
	local remotes = getOrCreate(ReplicatedStorage, "Folder", WeaponConfig.remotesFolderName)
	local fireRemote = getOrCreate(remotes, "RemoteEvent", WeaponConfig.fireRemoteName) :: RemoteEvent
	effectRemote = getOrCreate(remotes, "RemoteEvent", WeaponConfig.effectRemoteName) :: RemoteEvent

	fireRemote.OnServerEvent:Connect(onFire)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		lastFireTime[player] = nil
	end)
end

return WeaponService
