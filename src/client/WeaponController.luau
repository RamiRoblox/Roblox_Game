--!strict
-- Controlador de armas (cliente): lee el input, apunta, manda la intención de disparo al servidor
-- y dibuja los efectos. El daño y los impactos los decide el servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local WeaponConfig = require(ReplicatedStorage.Shared.Weapons.WeaponConfig)
local WeaponEffects = require(script.Parent.WeaponEffects)

local RECOIL_BIND = "WeaponRecoil"
local RECOIL_RECOVERY = 14 -- qué tan rápido vuelve la cámara tras la patada
local FACE_AIM_MIN_DISTANCE = 1.5 -- no girar al personaje si el punto de mira está pegado a él

type Session = {
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	tool: Tool,
	stats: WeaponConfig.WeaponStats,
	firing: boolean,
	nextFire: number,
	connections: { RBXScriptConnection },
}

local WeaponController = {}

local player = Players.LocalPlayer
local fireRemote: RemoteEvent? = nil
local session: Session? = nil
local recoilPitch = 0 -- radianes, se acumula con cada disparo y decae solo

local aimParams = RaycastParams.new()
aimParams.FilterType = Enum.RaycastFilterType.Exclude
aimParams.IgnoreWater = true

-- Punto del mundo hacia el que apunta el jugador (cursor con mouse, centro de pantalla en táctil/gamepad).
local function getAimPoint(character: Model, range: number): Vector3
	local camera = Workspace.CurrentCamera
	if not camera then
		return Vector3.zero
	end
	local screenPoint = if UserInputService.MouseEnabled
		then UserInputService:GetMouseLocation()
		else camera.ViewportSize / 2
	local ray = camera:ViewportPointToRay(screenPoint.X, screenPoint.Y)
	aimParams.FilterDescendantsInstances = { character }
	local result = Workspace:Raycast(ray.Origin, ray.Direction * range, aimParams)
	if result then
		return result.Position
	end
	return ray.Origin + ray.Direction * range
end

local function endSession()
	local current = session
	if not current then
		return
	end
	session = nil
	for _, connection in current.connections do
		connection:Disconnect()
	end
	if current.humanoid.Parent then
		current.humanoid.AutoRotate = true
	end
end

local function shoot(current: Session)
	local remote = fireRemote
	if not remote then
		return
	end
	local aimPoint = getAimPoint(current.character, current.stats.range)
	remote:FireServer(aimPoint)

	-- Feedback inmediato para el tirador (el resto de los jugadores lo ve cuando responde el servidor).
	local handle = current.tool:FindFirstChild("Handle")
	local muzzle = if handle then handle:FindFirstChild("Muzzle_Att") else nil
	local origin = if muzzle and muzzle:IsA("Attachment") then muzzle.WorldPosition else current.root.Position
	WeaponEffects.playMuzzle(current.character, current.tool.Name, origin)
	recoilPitch += math.rad(current.stats.recoilPitchDegrees)
end

-- Cada frame: el personaje mira hacia donde apunta y, si el botón está apretado, dispara según la cadencia.
local function step(current: Session)
	local aimPoint = getAimPoint(current.character, current.stats.range)
	local flat = (aimPoint - current.root.Position) * Vector3.new(1, 0, 1)
	if flat.Magnitude > FACE_AIM_MIN_DISTANCE then
		local position = current.root.Position
		current.root.CFrame = CFrame.lookAt(position, position + flat)
	end

	if not current.firing then
		return
	end
	local now = os.clock()
	if now < current.nextFire then
		return
	end
	local interval = 60 / current.stats.fireRate
	-- Si se atrasó mucho (lag, tab en segundo plano) no dispara en ráfaga para "recuperar".
	current.nextFire = if now - current.nextFire > interval then now + interval else current.nextFire + interval
	shoot(current)
end

local function beginSession(character: Model, tool: Tool, stats: WeaponConfig.WeaponStats)
	endSession()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		return
	end

	local current: Session = {
		character = character,
		humanoid = humanoid,
		root = root,
		tool = tool,
		stats = stats,
		firing = false,
		nextFire = 0,
		connections = {},
	}
	session = current
	humanoid.AutoRotate = false

	table.insert(
		current.connections,
		tool.Activated:Connect(function()
			current.firing = true
		end)
	)
	table.insert(
		current.connections,
		tool.Deactivated:Connect(function()
			current.firing = false
		end)
	)
	table.insert(
		current.connections,
		RunService.RenderStepped:Connect(function()
			step(current)
		end)
	)
	table.insert(current.connections, humanoid.Died:Connect(endSession))
end

local function onCharacterAdded(character: Model)
	character.ChildAdded:Connect(function(child: Instance)
		if not child:IsA("Tool") then
			return
		end
		local stats = WeaponConfig.get(child.Name)
		if stats then
			beginSession(character, child, stats)
		end
	end)
	character.ChildRemoved:Connect(function(child: Instance)
		if session and session.tool == child then
			endSession()
		end
	end)
	-- Por si la Tool ya estaba equipada cuando se conectó esto.
	local equipped = character:FindFirstChildOfClass("Tool")
	local stats = if equipped then WeaponConfig.get(equipped.Name) else nil
	if equipped and stats then
		beginSession(character, equipped, stats)
	end
end

-- Patada de cámara: se suma después del script de cámara cada frame y decae sola.
local function applyRecoil(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera or recoilPitch < 1e-4 then
		recoilPitch = 0
		return
	end
	camera.CFrame *= CFrame.Angles(recoilPitch, 0, 0)
	recoilPitch -= recoilPitch * math.min(1, RECOIL_RECOVERY * dt)
end

function WeaponController.start(): ()
	local remotes = ReplicatedStorage:WaitForChild(WeaponConfig.remotesFolderName)
	fireRemote = remotes:WaitForChild(WeaponConfig.fireRemoteName) :: RemoteEvent
	local effectRemote = remotes:WaitForChild(WeaponConfig.effectRemoteName) :: RemoteEvent

	effectRemote.OnClientEvent:Connect(
		function(userId: any, toolName: any, origin: any, endPosition: any, normal: any, hitHumanoid: any)
			if
				typeof(userId) ~= "number"
				or typeof(toolName) ~= "string"
				or typeof(origin) ~= "Vector3"
				or typeof(endPosition) ~= "Vector3"
				or typeof(normal) ~= "Vector3"
				or typeof(hitHumanoid) ~= "boolean"
			then
				return
			end
			local stats = WeaponConfig.get(toolName :: string)
			if not stats then
				return
			end
			-- El tirador local ya vio su fogonazo al disparar; los demás lo ven acá.
			if userId ~= player.UserId then
				local shooter = Players:GetPlayerByUserId(userId :: number)
				WeaponEffects.playMuzzle(
					if shooter then shooter.Character else nil,
					toolName :: string,
					origin :: Vector3
				)
			end
			WeaponEffects.playBullet(
				origin :: Vector3,
				endPosition :: Vector3,
				normal :: Vector3,
				hitHumanoid :: boolean,
				stats.tracerSpeed
			)
		end
	)

	RunService:BindToRenderStep(RECOIL_BIND, Enum.RenderPriority.Camera.Value + 1, applyRecoil)

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

return WeaponController
