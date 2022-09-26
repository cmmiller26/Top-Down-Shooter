local FireState = {}

function FireState.new(origin, velocity, fireID, playerTick)
    return {
        origin = origin,
        velocity = velocity,
        fireID = fireID,
        playerTick = playerTick
    }
end

return FireState