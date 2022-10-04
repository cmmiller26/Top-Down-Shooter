local FireState = {}

function FireState.new(origin, direction, speed, playerTick)
    return {
        origin = origin,
        direction = direction,
        speed = speed,
        playerTick = playerTick
    }
end

return FireState