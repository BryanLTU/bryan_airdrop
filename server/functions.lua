FrameworkObj = nil

if Config.Framework == 'esx' then
    FrameworkObj = exports['es_extended']:getSharedObject()
elseif Config.Framework == 'qbcore' then
    FrameworkObj = exports['qb-core']:GetCoreObject()
end

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
    if Config.Framework == 'esx' then
        FrameworkObj.GetPlayerFromId(source).addInventoryItem(item, amount)
    elseif Config.Framework == 'qbcore' then
        FrameworkObj.Functions.GetPlayer(source).Functions.AddItem(item, amount)
    end
end

_AddPlayerWeapon = function(source, weapon)
    if Config.Framework == 'esx' then
        FrameworkObj.GetPlayerFromId(source).addWeapon(weapon, 1)
    end
end

_AddPlayerMoney = function(source, account, amount)
    if Config.Framework == 'esx' then
        FrameworkObj.GetPlayerFromId(source).addAccountMoney(account, amount)
    elseif Config.Framework == 'qbcore' then
        FrameworkObj.Functions.GetPlayer(source).Functions.AddMoney(account, amount)
    end
end

_AddPlayerVehicle = function(source, model, plate)
    if Config.Framework == 'esx' then
        MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)', {
            FrameworkObj.GetPlayerFromId(source).getIdentifier(),
            plate,
            json.encode({ model = joaat(model), plate = plate })
        })
    elseif Config.Framework == 'qbcore' then
        local pData = FrameworkObj.Functions.GetPlayer(source)

        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            pData.PlayerData.license,
            pData.PlayerData.citizenid,
            model,
            GetHashKey(vehicle),
            '{}',
            plate,
            'pillboxgarage',
            0
        })
    end
end