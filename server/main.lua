ESX = exports['es_extended']:getSharedObject()
local airdrops = {}
local tryCount = 0
local cooldown = math.random(Config.Airdrops.Cooldown.min, Config.Airdrops.Cooldown.max)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if Config.Debug then print(string.format('%s Started Successfully | Server Side', GetCurrentResourceName())) end

        if not Config.Airdrops.OnlyCommand then
            Citizen.CreateThread(function() StartAirdropLoop(); end)
        end
    end
end)

RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
    TriggerClientEvent('bryan_airdrops:syncAirdrops', playerId, airdrops)
end)

RegisterNetEvent('bryan_airdrops:pickupAirdrop', function(id)
    local airdrop = GetAirdrop(id)

    if airdrop then
        RewardPlayer(source, airdrop.items)
        RemoveAirdrop(id)
        TriggerClientEvent('bryan_airdrops:removeObject', -1, id)
        TriggerClientEvent('bryan_airdrops:syncAirdrops', -1, airdrops)
    else
        if Config.Debug then
            print('Could not find airdrop by it\'s ID')
        end
    end
end)

RegisterNetEvent('bryan_airdrops:airdropLanded', function(id)
    local airdropIndex = GetAirdropIndex(id)

    airdrops[airdropIndex].landed = true
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

if Config.Command.Enabled then
    lib.addCommand(Config.Command.Name, {
        help = _U('command_help'),
        params = {
            {
                name = 'lootTable',
                help = _U('command_args_lootTable'),
                type = 'number',
                optional = true
            }
        },
        restricted = Config.Command.Groups
    }, function(source, args, raw)
        if Config.Debug then print(args.lootTable == nil, Config.LootTables[args.lootTable] ~= nil) end

        if args.lootTable ~= nil and Config.LootTables[args.lootTable] == nil then
            TriggerClientEvent('esx:showNotification', source, _U('command_error_loottable_not_found', args.lootTable))
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

SpawnAirdrop = function(lootTable, customCoords)
    local randomLocation = Config.Locations[math.random(1, #Config.Locations)]
    local isLocationTaken = IsLocationTaken(randomLocation)
    
    if Config.Debug then print(tryCount > 10, not isLocationTaken) end
    if tryCount > 10 or not isLocationTaken or customCoords then
        tryCount = 0
        
        local airdropId = math.random(10000, 99999)
        local airdropItems = SelectLoottable(lootTable)

        local coords = randomLocation

        if customCoords then coords = customCoords
        elseif coords.z < 150.0 then coords = vector3(randomLocation.x, randomLocation.y, 200.0) end

        if Config.RemovePreviousAirdrops then
            TriggerClientEvent('bryan_airdrops:removeAllObjects', -1)
            airdrops = {}
        end

        table.insert(airdrops, {
            id = airdropId,
            items = airdropItems,
            coords = coords
        })

        if Config.Debug then print('Airdrop Spawned') end
        TriggerClientEvent('bryan_airdrops:syncAirdrops', -1, airdrops)
        Config.NotifyPlayers(_U('notification_airdrop_spawned'))

        Citizen.CreateThread(function()
            local airdropIndex = GetAirdropIndex(airdropId)

            while not airdrops[airdropIndex].landed do
                airdrops[airdropIndex].coords = airdrops[airdropIndex].coords - vector3(0.0, 0.0, 0.01 * Config.Airdrops.FallSpeed)
                Citizen.Wait(1)
            end

            if Config.Debug then print(string.format('Airdrop (ID: %s) Landed', airdrops[airdropIndex].id)) end
        end)
    elseif isLocationTaken then 
        tryCount = tryCount + 1
        SpawnAirdrop(lootTable)
    end
end

IsLocationTaken = function(location)
    for k, v in pairs(airdrops) do
        if v.coords == location then
            return true
        end
    end

    return false
end

SelectLoottable = function(lootTable)
    if lootTable ~= nil then
        return Config.LootTables[lootTable].Items
    else
        local randomLootTable = Config.LootTables[math.random(1, #Config.LootTables)]
        local chance = math.random(1, 100)

        while randomLootTable.Chance < chance do
            Citizen.Wait(10)
            
            randomLootTable = Config.LootTables[math.random(1, #Config.LootTables)]
            chance = math.random(1, 100)

            if Config.Debug then print('searching ' .. randomLootTable.Chance < chance) end
        end

        return randomLootTable.Items
    end
end

RestartCooldown = function()
    cooldown = math.random(Config.Airdrops.Cooldown.min, Config.Airdrops.Cooldown.max)
end

RemoveAirdrop = function(id)
    for k, v in pairs(airdrops) do
        if v.id == id then
            airdrops[k] = nil
            break
        end
    end
end

RewardPlayer = function(source, items)
    local xPlayer = ESX.GetPlayerFromId(source)

    for k, v in pairs(items) do
        if v.type == 'item' then
            xPlayer.addInventoryItem(v.name, v.count)
        elseif v.type == 'weapon' then
            xPlayer.addWeapon(v.name, v.count)
        elseif v.type == 'account' then
            xPlayer.addAccountMoney(v.name, v.count)
        end
    end
end

GetAirdrop = function(id)
    for k, v in pairs(airdrops) do
        if v.id == id then
            return v
        end
    end

    return nil
end

GetAirdropIndex = function(id)
    for k, v in pairs(airdrops) do
        if v.id == id then
            return k
        end
    end

    return nil
end