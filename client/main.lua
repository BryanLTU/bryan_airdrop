ESX = exports['es_extended']:getSharedObject()
local airdrops = {}
local Blips = {}

Citizen.CreateThread(function()
    while ESX.GetPlayerData().job == nil do Citizen.Wait(100) end

    Citizen.CreateThread(function() StartScript(); end)
    Citizen.CreateThread(function() ShowLocations(); end)
    if Config.Debug then print(string.format('%s Started Successfully | Client Side', GetCurrentResourceName())) end
end)

RegisterNetEvent('bryan_airdrop:client:addBlips', function(airdropId, coords)
    if Config.Blip then
        table.insert(Blips, {
            airdropId = airdropId,
            blip = _AddBlip(coords),
        })
    end

    if Config.Radius then
        table.insert(Blips, {
            airdropId = airdropId,
            blip = _AddRadius(coords)
        })
    end
end)

RegisterNetEvent('bryan_airdrop:client:removeBlipsWithAirdropId', function(airdropId)
    RemoveBlips(airdropId)
end)

RegisterNetEvent('bryan_airdrop:client:removeAllBlips', function()
    RemoveBlips()
end)

RegisterNetEvent('bryan_airdrop:client:notification', function(msg, type)
    _Notification(msg, type)
end)

RegisterNetEvent('bryan_airdrop:client:startParticles', function(airdropNetId)
    local object = NetworkGetEntityFromNetworkId(airdropNetId)

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Citizen.Wait(10) end

    UseParticleFxAssetNextCall("core")
    SetParticleFxNonLoopedColour(1.0, 0.0, 0.0)
    StartNetworkedParticleFxLoopedOnEntity('weap_heist_flare_trail', object, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0)
end)

RegisterNetEvent('bryan_airdrop:client:attachParachute', function(vehicleNetId, parachuteNetId)
    local vehicle, parachute = NetworkGetEntityFromNetworkId(vehicleNetId), NetworkGetEntityFromNetworkId(parachuteNetId)

    AttachEntityToEntity(parachute, vehicle, GetEntityBoneIndexByName(vehicle, 'roof'), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, false, false, false, GetEntityRotation(vehicle), true)
end)

RemoveBlips = function(airdropId)
    for k, v in ipairs(Blips) do
        if not airdropId or (airdropId and v.airdropId == airdropId) then
            RemoveBlip(v.blip)
            table.remove(Blips, k)
        end
    end
end

ShowLocations = function()
    while true do
        local wait = 500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for k, v in pairs(airdrops) do
            if v.landed then
                local distance = GetDistanceBetweenCoords(coords, v.coords, true)

                if distance <= 3.0 then
                    wait = 2
                    ESX.Game.Utils.DrawText3D(v.coords, locale('3d_press_to_pickup'), 0.8, 4)

                    if IsControlJustPressed(1, 51) then
                        Config.ProgressBar(locale('progress_bar_picking_up'), Config.Airdrops.CollectTime * 1000)

                        TriggerServerEvent('bryan_airdrops:pickupAirdrop', v.id)
                    end
                end
            end
        end

        Citizen.Wait(wait)
    end
end