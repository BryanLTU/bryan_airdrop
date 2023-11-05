_GetClosestPlayer = function(coords)
    local closestPlayer, closestDistance = -1, -1

    for k, v in ipairs(GetPlayers()) do
        local distance = #(coords - GetEntityCoords(GetPlayerPed(v)))

        if closestPlayer == -1 or distance < closestDistance then
            closestPlayer = v
            closestDistance = distance
        end
    end

    return closestPlayer
end