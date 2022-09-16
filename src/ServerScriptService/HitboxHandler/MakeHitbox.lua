local function MakeHitbox(hitboxState)
    local character = script.HitboxCharacter:Clone()
    character.Head.CFrame = hitboxState["Head"]
    character.Torso.CFrame = hitboxState["Torso"]
    character["Left Arm"].CFrame = hitboxState["Left Arm"]
    character["Right Arm"].CFrame = hitboxState["Right Arm"]
    character["Left Leg"].CFrame = hitboxState["Left Leg"]
    character["Right Leg"].CFrame = hitboxState["Right Leg"]

    return character
end

return MakeHitbox