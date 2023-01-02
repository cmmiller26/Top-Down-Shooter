local Players = game:GetService("Players")

local TDSPlayer = require(script.TDSPlayer)

local players = {}

Players.PlayerAdded:Connect(function(player)
    players[player] = TDSPlayer.new(player)
end)
Players.PlayerRemoving:Connect(function(player)
    players[player]:Destroy()
end)