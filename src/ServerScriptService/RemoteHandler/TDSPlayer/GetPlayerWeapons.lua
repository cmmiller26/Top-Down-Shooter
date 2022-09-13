local ServerStorage = game:GetService("ServerStorage")

local Weapons = ServerStorage.Weapons

-- TODO: Add DataStore functionality for getting weapons
function GetPlayerWeapons(player)
    local weapons = {}
    for _, weapon in ipairs(Weapons:GetChildren()) do
        table.insert(weapons, weapon:Clone())
    end
    return weapons
end

return GetPlayerWeapons