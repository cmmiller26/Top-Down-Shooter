local FireState = {}

function FireState.new(origin, velocity, playerTick)
    return {
        origin = origin,
        velocity = velocity,
        playerTick = playerTick
    }
end

return FireState