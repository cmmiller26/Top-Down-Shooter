local HitboxState = {}

function HitboxState.new(character)
    return {
        ["Head"] = character.Head.CFrame,
        ["Torso"] = character.Torso.CFrame,
        ["Left Arm"] = character["Left Arm"].CFrame,
        ["Right Arm"] = character["Right Arm"].CFrame,
        ["Left Leg"] = character["Left Leg"].CFrame,
        ["Right Leg"] = character["Right Leg"].CFrame
    }
end

return HitboxState