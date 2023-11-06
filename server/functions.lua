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

_AddPlayerItem = function(source, item, amount)
    ESX.GetPlayerFromId(source).addInventoryItem(item, amount)
end

_AddPlayerWeapon = function(source, weapon)
    ESX.GetPlayerFromId(source).addWeapon(weapon, 1)
end

_AddPlayerMoney = function(source, account, amount)
    ESX.GetPlayerFromId(source).addAccountMoney(account, amount)
end