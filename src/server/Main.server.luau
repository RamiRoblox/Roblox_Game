--!strict
-- Punto de entrada del servidor (ServerScriptService.Main).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hello = require(ReplicatedStorage.Shared.Hello)
local WeaponService = require(script.Parent.WeaponService)

print(Hello.greet("el servidor"))

WeaponService.start()
