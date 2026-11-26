--!strict
-- Punto de entrada del cliente (StarterPlayer.StarterPlayerScripts.Main).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hello = require(ReplicatedStorage.Shared.Hello)
local WeaponController = require(script.Parent.WeaponController)

print(Hello.greet("el cliente"))

WeaponController.start()
