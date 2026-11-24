--!strict
-- Punto de entrada del cliente (StarterPlayer.StarterPlayerScripts.Main).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hello = require(ReplicatedStorage.Shared.Hello)

print(Hello.greet("el cliente"))
