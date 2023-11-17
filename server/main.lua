local Airdrops = {}
local tryCount = 0
local cooldown = Config.Cooldown * 60 * 1000

lib.locale()

if Config.Command.Enabled then
    lib.addCommand(Config.Command.Name, {
        help = locale('command_help'),
        params = {
            {
                name = 'lootTable',
                help = locale('command_args_lootTable'),
                type = 'number',
                optional = true
            }
        },
        restricted = Config.Command.Groups
    }, function(source, args, raw)
        if Config.Debug then print(args.lootTable == nil, Config.LootTables[args.lootTable] ~= nil) end

        if args.lootTable ~= nil and Config.LootTables[args.lootTable] == nil then
            TriggerClientEvent('bryan_airdrop:client:notification', source, locale('command_error_loottable_not_found', args.lootTable), 'error')
            return
        end

        if Config.Command.ResetCooldown then
            RestartCooldown()
        end

        if Config.Command.ExecutorCoords and source > 0 then
            SpawnAirdrop(args.lootTable, GetEntityCoords(GetPlayerPed(source)) + vector3(0.0, 0.0, 150.0))
            return
        end

        SpawnAirdrop(args.lootTable)
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if Config.Debug then print(string.format('%s Started Successfully | Server Side', GetCurrentResourceName())) end

        if not Config.OnlyCommand then
            Citizen.CreateThread(function() StartAirdropLoop(); end)
        end
    end
end)

RegisterNetEvent('bryan_airdrops:server:airdropLanded', function(airdropId)
    SetAirdropLanded(airdropId, true)
end)

RegisterNetEvent('bryan_airdrops:server:changeGroundCheckPlayer', function(airdropId)
    InitializeGroundCheck(airdropId)
end)

RegisterNetEvent('bryan_airdrops:server:collectAirdrop', function(data)
    local airdrop = GetAirdrop(data.airdropId)

    if not airdrop then return end
    if airdrop.collected then return end

    SetAirdropCollected(airdrop.id, true)

    TriggerClientEvent('bryan_airdrop:client:removeAirdropTarget', -1, NetworkGetNetworkIdFromEntity(airdrop.object))
    
    if airdrop.type == 'vehicle' then
        DeleteEntity(airdrop.parachute)
    else
        DeleteEntity(airdrop.object)
    end
    
    RewardPlayer(source, airdrop.id, { plate = airdrop.type == vehicle and GetVehicleNumberPlateText(airdrop.object) })
end)

StartAirdropLoop = function()
    while true do
        while cooldown > 0 do
            if Config.Debug then print(string.format('%s Minutes Till Next Airdrop Spawn', cooldown)) end
            Citizen.Wait(60 * 1000)
            cooldown = cooldown - 1
        end

        RestartCooldown()

        if Config.SpawnOffline or (not Config.SpawnOffline and #GetPlayers() > 0) then
            SpawnAirdrop()
        end

        Citizen.Wait(10)
    end
end

SpawnAirdrop = function(lootTable, customCoords)
    local randomLocation = GetRandomAirdropLocation()
    local isLocationTaken = IsLocationTaken(randomLocation)
    
    if Config.Debug then print(tryCount > 10, not isLocationTaken) end
    
    if tryCount > 10 or not isLocationTaken or customCoords then
        tryCount = 0
        
        local coords = customCoords or randomLocation
        local closestPlayer = _GetClosestPlayer(coords)
        local lootTableId = lootTable or GetRandomLootTableId()
        local airdropId, airdropType = GetLatestAirdropId(), GetAirdropType(lootTableId)

        if coords.z < 150.0 then coords.z = 150.0 end

        if Config.RemovePreviousAirdrops then RemoveAirdrops() end

        local object = nil
        
        if airdropType == 'items' then
            object = CreateObject(GetHashKey(Config.ObjectModel), coords.x, coords.y, coords.z, true, false, false)
        elseif airdropType == 'vehicle' then
            object = CreateVehicle(GetHashKey(GetAirdropVehicle(lootTableId)), coords.x, coords.y, coords.z, 0.0, true, false)
        end
        
        if object == nil then return end
        
        while not DoesEntityExist(object) do Wait(0) end

        FreezeEntityPosition(object, true)

        table.insert(Airdrops, {
            id = airdropId,
            lootTableId = lootTableId,
            type = airdropType,
            coords = coords,
            object = object,
            landed = false,
            collected = false,
        })

        local airdropIndex = GetAirdropIndex(airdropId)
        
        if airdropType == 'vehicle' then
            local parachute = CreateObject(GetHashKey('p_parachute1_mp_dec'), coords.x, coords.y, coords.z + 10.0, true, false, false)
            while not DoesEntityExist(parachute) do Wait(0) end

            FreezeEntityPosition(parachute, true)
            
            local plate = lib.callback.await('bryan_airdrop:client:getPlate', closestPlayer)
            SetVehicleNumberPlateText(object, plate)

            TriggerClientEvent('bryan_airdrop:client:attachParachute', closestPlayer, NetworkGetNetworkIdFromEntity(object), NetworkGetNetworkIdFromEntity(parachute))
        
            Airdrops[airdropIndex].parachute = parachute
        end

        if Config.Particles then
            if closestPlayer then
                TriggerClientEvent('bryan_airdrop:client:startParticles', closestPlayer, NetworkGetNetworkIdFromEntity(object))
            end
        end

        TriggerClientEvent('bryan_airdrop:client:addBlips', -1, airdropId, coords)
        TriggerClientEvent('bryan_airdrop:client:prepareAirdropForClient', -1, airdropId, NetworkGetNetworkIdFromEntity(object))

        if Config.Debug then print('Airdrop Spawned') end

        InitializeGroundCheck(airdropId)
        
        Citizen.CreateThread(function()
            while DoesEntityExist(object) and not Airdrops[airdropIndex].landed do
                Airdrops[airdropIndex].coords = Airdrops[airdropIndex].coords - vector3(0.0, 0.0, 0.01 * Config.FallSpeed)

                SetEntityCoords(object, Airdrops[airdropIndex].coords.x, Airdrops[airdropIndex].coords.y, Airdrops[airdropIndex].coords.z)

                Citizen.Wait(0)
            end

            if Config.Debug then print(string.format('Airdrop (ID: %s) Landed', airdrops[airdropIndex].id)) end
        end)
    elseif isLocationTaken then 
        tryCount = tryCount + 1
        SpawnAirdrop(lootTable)
    end
end

GetRandomAirdropLocation = function()
    local randomIndex = math.random(1, #Config.Locations)
    
    return Config.Locations[randomIndex]
end

GetLatestAirdropId = function()
    local latestId = 0

    for k, v in ipairs(Airdrops) do
        if latestId <= v.id then
            latestId = v.id + 1
        end
    end

    return latestId
end

GetAirdropType = function(lootTableId)
    for k, v in ipairs(Config.LootTables) do
        if v.id == lootTableId then
            return v.type
        end
    end

    return nil
end

GetAirdropVehicle = function(lootTableId)
    for k, v in ipairs(Config.LootTables) do
        if v.id == lootTableId then
            return v.vehicle
        end
    end

    return nil
end

GetRandomLootTableId = function()
    local randomLootTable
    local myChance = math.random(0, 100)

    while not randomLootTable or myChance > randomLootTable.chance do
        Citizen.Wait(10)

        randomLootTable = Config.LootTables[math.random(1, #Config.LootTables)]
    end

    return randomLootTable.id
end

GetAirdropIndex = function(airdropId)
    for k, v in ipairs(Airdrops) do
        if v.id == airdropId then
            return k
        end
    end

    return nil
end

SetAirdropLanded = function(airdropId, value)
    for k, v in ipairs(Airdrops) do
        if v.id == airdropId then
            Airdrops[k].landed = value
            break
        end
    end
end

SetAirdropCollected = function(airdropId, value)
    for k, v in ipairs(Airdrops) do
        if v.id == airdropId then
            Airdrops[k].collected = value
            break
        end
    end
end

IsLocationTaken = function(location)
    for k, v in ipairs(Airdrops) do
        if v.coords == location then
            return true
        end
    end

    return false
end

RestartCooldown = function()
    cooldown = Config.Cooldown * 60 * 1000
end

RemoveAirdrop = function(airdropId)
    for k, v in ipairs(Airdrops) do
        if v.id == airdropId then
            DeleteEntity(v.object)
            TriggerClientEvent('bryan_airdrop:client:removeBlipsWithAirdropId', -1, v.id)

            table.remove(Airdrops, k)

            break
        end
    end
end

RemoveAirdrops = function()
    for k, v in ipairs(Airdrops) do
        DeleteEntity(v.object)
    end

    TriggerClientEvent('bryan_airdrop:client:removeAllBlips', -1)

    Airdrops = {}
end

RewardPlayer = function(source, airdropId, data)
    local airdrop = GetAirdrop(airdropId)
    
    if airdrop.type == 'items' then
        local items = Config.LootTables[airdrop.lootTableId].items

        for k, v in ipairs(items) do
            if v.type == 'item' then
                _AddPlayerItem(source, v.name, v.count)
            elseif v.type == 'weapon' then
                _AddPlayerWeapon(source, v.name)
            elseif v.type == 'account' then
                _AddPlayerMoney(source, v.name, v.count)
            end
        end
    elseif airdrop.type == 'vehicle' then
        _AddPlayerVehicle(source, Config.LootTables[airdrop.lootTableId].vehicle, data.plate)
    end
end

GetAirdrop = function(id)
    for k, v in pairs(Airdrops) do
        if v.id == id then
            return v
        end
    end

    return nil
end

InitializeGroundCheck = function(airdropId)
    local airdrop = GetAirdrop(airdropId)
    local closestPlayer = _GetClosestPlayer(airdrop.coords)

    TriggerClientEvent('bryan_airdrop:client:startGroundCheck', closestPlayer, airdropId, NetworkGetNetworkIdFromEntity(airdrop.object))
end