--!strict
-- Controlador de armas (cliente): lee el input, apunta, manda la intención de disparo al servidor
-- y dibuja los efectos. El daño y los impactos los decide el servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ViewmodelConfig = require(ReplicatedStorage.Shared.Weapons.ViewmodelConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.Weapons.WeaponConfig)
local WeaponAnimations = require(script.Parent.WeaponAnimations)
local WeaponEffects = require(script.Parent.WeaponEffects)
local WeaponMotion = require(script.Parent.WeaponMotion)
local WeaponTuning = require(script.Parent.WeaponTuning)
local WeaponViewmodel = require(script.Parent.WeaponViewmodel)

local RECOIL_BIND = "WeaponRecoil"
local VIEWMODEL_BIND = "WeaponViewmodel"
local FACE_AIM_MIN_DISTANCE = 1.5 -- no girar al personaje si el punto de mira está pegado a él
-- Después de pedir una recarga no se pide otra hasta que pase la recarga + este margen (espera al servidor).
local RELOAD_RETRY_MARGIN = 0.5

type Session = {
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	tool: Tool,
	stats: WeaponConfig.WeaponStats,
	firing: boolean,
	nextFire: number,
	connections: { RBXScriptConnection },
	viewmodel: WeaponViewmodel.Viewmodel?,
	motion: WeaponMotion.Motion, -- balanceo, paso y salto del viewmodel
	previousCameraMode: Enum.CameraMode, -- se restaura al guardar el arma
	aiming: boolean, -- el botón de apuntar está apretado
	aimProgress: number, -- 0 = cadera, 1 = apuntando (avanza en el tiempo de "apuntar.tiempo")
	baseFieldOfView: number, -- campo de visión sin apuntar (se restaura al guardar el arma)
	baseMouseSensitivity: number, -- sensibilidad del mouse sin apuntar (ídem)
	animator: WeaponAnimations.Animator, -- recarga del viewmodel
	ammo: number, -- balas que le quedan según el cliente (el servidor tiene la cuenta real en la Tool)
	lastReloadRequest: number, -- os.clock() del último pedido de recarga
	runBlend: number, -- 0 = arma normal, 1 = pose de correr (baja y cruzada)
	lastShotTime: number, -- os.clock() del último tiro (después de disparar tarda un poco en volver a bajar)
}

local WeaponController = {}

local player = Players.LocalPlayer
local fireRemote: RemoteEvent? = nil
local reloadRemote: RemoteEvent? = nil
local session: Session? = nil
local cameraRecoilOffset = CFrame.identity -- giro que el retroceso le sumó a la cámara en este frame

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

-- Botón de apuntar: clic derecho, o el gatillo izquierdo (L2) en joystick.
local function isAimInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2
end

-- Botón de recargar: R, o X en joystick.
local function isReloadInput(input: InputObject): boolean
	return input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX
end

-- Botón de inspeccionar: V, o flecha arriba en joystick.
local function isInspectInput(input: InputObject): boolean
	return input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.DPadUp
end

-- Curva suave: arranca y termina despacio, así llevar el arma a la mira no se ve mecánico.
local function smoothstep(x: number): number
	return x * x * (3 - 2 * x)
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
	RunService:UnbindFromRenderStep(VIEWMODEL_BIND)
	if current.viewmodel then
		WeaponViewmodel.destroy(current.viewmodel)
	end
	player.CameraMode = current.previousCameraMode
	local camera = Workspace.CurrentCamera
	if camera then
		camera.FieldOfView = current.baseFieldOfView
	end
	UserInputService.MouseDeltaSensitivity = current.baseMouseSensitivity
	if current.humanoid.Parent then
		current.humanoid.AutoRotate = true
	end
end

-- Cañón del viewmodel, si se está viendo (primera persona).
local function getViewmodelMuzzle(current: Session?): Attachment?
	local viewmodel = if current then current.viewmodel else nil
	if viewmodel and viewmodel.visible then
		return viewmodel.muzzle
	end
	return nil
end

local function shoot(current: Session)
	local remote = fireRemote
	if not remote then
		return
	end
	local aimPoint = getAimPoint(current.character, current.stats.range)
	remote:FireServer(aimPoint)

	-- Feedback inmediato para el tirador (el resto de los jugadores lo ve cuando responde el servidor).
	-- En primera persona los efectos salen del viewmodel, que es el arma que ve el jugador.
	local viewmodelMuzzle = getViewmodelMuzzle(current)
	local viewmodel = current.viewmodel
	if viewmodelMuzzle and viewmodel then
		WeaponEffects.playMuzzleFrom(
			viewmodelMuzzle,
			viewmodel.ejection,
			current.tool.Name,
			viewmodelMuzzle.WorldPosition
		)
	else
		local handle = current.tool:FindFirstChild("Handle")
		local muzzle = if handle then handle:FindFirstChild("Muzzle_Att") else nil
		local origin = if muzzle and muzzle:IsA("Attachment") then muzzle.WorldPosition else current.root.Position
		WeaponEffects.playMuzzle(current.character, current.tool.Name, origin)
	end
	WeaponMotion.fire(current.motion)
	current.ammo -= 1
	current.lastShotTime = os.clock()
end

-- Recargando: mientras se ve la animación o mientras el servidor dice que la recarga sigue.
local function isReloading(current: Session): boolean
	return WeaponAnimations.isPlaying(current.animator, "Reload")
		or current.tool:GetAttribute(WeaponConfig.reloadingAttribute) == true
end

-- Pide recargar al servidor y arranca la animación ya (el servidor llena el cargador cuando termina).
local function requestReload(current: Session)
	local remote = reloadRemote
	local stats = current.stats
	if not remote or isReloading(current) or current.ammo >= stats.magazineSize then
		return
	end
	local now = os.clock()
	if now - current.lastReloadRequest < stats.reloadTime + RELOAD_RETRY_MARGIN then
		return
	end
	current.lastReloadRequest = now
	remote:FireServer()
	WeaponAnimations.play(current.animator, "Reload", stats.reloadTime)
end

-- Inspeccionar el arma (solo visual, no le avisa al servidor). No se puede mientras recarga o apunta.
local function startInspect(current: Session)
	if isReloading(current) or current.aiming or WeaponAnimations.isPlaying(current.animator, "Inspect") then
		return
	end
	WeaponAnimations.play(current.animator, "Inspect", ViewmodelConfig.valores.inspeccion.duracion)
end

-- Disparar o apuntar cortan la inspección (el arma vuelve a su lugar en un instante).
local function stopInspect(current: Session)
	if WeaponAnimations.isPlaying(current.animator, "Inspect") then
		WeaponAnimations.stop(current.animator)
	end
end

-- El servidor cambió la munición de la Tool. Si llenó el cargador (recarga) se toma su valor; si no, el menor
-- de los dos, porque los avisos del servidor llegan con atraso respecto de los tiros que ya contó el cliente.
local function onServerAmmo(current: Session)
	local serverAmmo = current.tool:GetAttribute(WeaponConfig.ammoAttribute)
	if typeof(serverAmmo) ~= "number" then
		return
	end
	if serverAmmo >= current.stats.magazineSize then
		current.ammo = serverAmmo
	else
		current.ammo = math.min(current.ammo, serverAmmo)
	end
end

-- Cada frame: el personaje mira hacia donde apunta y, si el botón está apretado, dispara según la cadencia.
local function step(current: Session)
	local aimPoint = getAimPoint(current.character, current.stats.range)
	local flat = (aimPoint - current.root.Position) * Vector3.new(1, 0, 1)
	if flat.Magnitude > FACE_AIM_MIN_DISTANCE then
		local position = current.root.Position
		current.root.CFrame = CFrame.lookAt(position, position + flat)
	end

	if not current.firing or isReloading(current) then
		return
	end
	stopInspect(current)
	if current.ammo <= 0 then
		requestReload(current) -- sin balas: recarga sola al apretar el gatillo
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
		viewmodel = nil,
		motion = WeaponMotion.new(),
		previousCameraMode = player.CameraMode,
		aiming = false,
		aimProgress = 0,
		baseFieldOfView = if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView else 70,
		baseMouseSensitivity = UserInputService.MouseDeltaSensitivity,
		animator = WeaponAnimations.new(),
		ammo = stats.magazineSize,
		lastReloadRequest = -math.huge,
		runBlend = 0,
		lastShotTime = -math.huge,
	}
	session = current
	humanoid.AutoRotate = false
	local serverAmmo = tool:GetAttribute(WeaponConfig.ammoAttribute)
	if typeof(serverAmmo) == "number" then
		current.ammo = serverAmmo
	end

	-- Con el arma en la mano se juega en primera persona, con el viewmodel (arma + brazos) pegado a la cámara.
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	local viewmodel = WeaponViewmodel.create(character, tool)
	current.viewmodel = viewmodel
	if viewmodel then
		-- Después de la cámara (y de la patada de retroceso), para usar su posición final de este frame.
		RunService:BindToRenderStep(VIEWMODEL_BIND, Enum.RenderPriority.Camera.Value + 2, function(dt: number)
			local camera = Workspace.CurrentCamera
			if not camera then
				return
			end
			-- Apuntar: avanza (o vuelve) en "apuntar.tiempo" segundos, con zoom y menos sensibilidad.
			-- Mientras recarga no se puede apuntar.
			local aimConfig = ViewmodelConfig.valores.apuntar
			local direction = if current.aiming and not isReloading(current) then 1 else -1
			current.aimProgress =
				math.clamp(current.aimProgress + direction * dt / math.max(aimConfig.tiempo, 0.01), 0, 1)
			local aimBlend = smoothstep(current.aimProgress)
			camera.FieldOfView = current.baseFieldOfView + (aimConfig.campoVision - current.baseFieldOfView) * aimBlend
			UserInputService.MouseDeltaSensitivity = current.baseMouseSensitivity
				* (1 + (aimConfig.sensibilidad - 1) * aimBlend)

			local grounded = current.humanoid.FloorMaterial ~= Enum.Material.Air
			local velocity = current.root.AssemblyLinearVelocity

			-- Correr: moviéndose rápido por el piso, sin disparar, apuntar ni animar, el arma baja y se cruza.
			local runConfig = ViewmodelConfig.valores.correr
			local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			local running = grounded
				and horizontalSpeed >= runConfig.velocidadMinima
				and not current.aiming
				and not current.firing
				and not WeaponAnimations.isPlaying(current.animator)
				and os.clock() - current.lastShotTime > runConfig.pausaTrasDisparo
			local runSpeed = if running then runConfig.entrada else runConfig.salida
			current.runBlend += ((if running then 1 else 0) - current.runBlend) * math.min(1, runSpeed * dt)

			-- El balanceo mide los giros de la cámara SIN la patada de retroceso (si no, cada tiro lo movería).
			local aimCamera = camera.CFrame * cameraRecoilOffset:Inverse()
			local motionOffset = WeaponMotion.update(current.motion, dt, aimCamera, velocity, grounded, aimBlend)
			local pose = WeaponAnimations.update(current.animator)
			WeaponViewmodel.update(viewmodel, camera.CFrame, dt, motionOffset, aimBlend, pose, current.runBlend)
		end)
	end

	table.insert(
		current.connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if gameProcessed then
				return
			end
			if isAimInput(input) then
				current.aiming = true
				stopInspect(current)
			elseif isReloadInput(input) then
				requestReload(current) -- si estaba inspeccionando, la recarga la reemplaza
			elseif isInspectInput(input) then
				startInspect(current)
			end
		end)
	)
	table.insert(
		current.connections,
		tool:GetAttributeChangedSignal(WeaponConfig.ammoAttribute):Connect(function()
			onServerAmmo(current)
		end)
	)
	table.insert(
		current.connections,
		UserInputService.InputEnded:Connect(function(input: InputObject)
			if isAimInput(input) then
				current.aiming = false
			end
		end)
	)

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

-- Retroceso de cámara, después del script de cámara. Ese script arranca cada frame desde donde quedó la cámara,
-- así que acá se suma solo el CAMBIO del retroceso respecto del frame anterior: si se sumara entero cada frame,
-- la mira subiría para siempre. Así, cuando el resorte vuelve a cero, la cámara vuelve a donde estaba.
local function applyRecoil(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local current = session
	local newOffset = if current then WeaponMotion.updateCamera(current.motion, dt) else CFrame.identity
	camera.CFrame *= cameraRecoilOffset:Inverse() * newOffset
	cameraRecoilOffset = newOffset
end

function WeaponController.start(): ()
	WeaponTuning.start()

	local remotes = ReplicatedStorage:WaitForChild(WeaponConfig.remotesFolderName)
	fireRemote = remotes:WaitForChild(WeaponConfig.fireRemoteName) :: RemoteEvent
	reloadRemote = remotes:WaitForChild(WeaponConfig.reloadRemoteName) :: RemoteEvent
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
			local tracerOrigin = origin :: Vector3
			if userId ~= player.UserId then
				local shooter = Players:GetPlayerByUserId(userId :: number)
				WeaponEffects.playMuzzle(
					if shooter then shooter.Character else nil,
					toolName :: string,
					origin :: Vector3
				)
			else
				-- El servidor calcula desde el cañón de la Tool real (escondida): la trazadora propia sale del viewmodel.
				local viewmodelMuzzle = getViewmodelMuzzle(session)
				if viewmodelMuzzle then
					tracerOrigin = viewmodelMuzzle.WorldPosition
				end
			end
			WeaponEffects.playBullet(
				tracerOrigin,
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
