local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TDSPlayer = require(script.TDSPlayer)
ReplicatedStorage.Controllers.TDSController.Connect.OnServerEvent:Connect(function(player)
    TDSPlayer.new(player)
end)