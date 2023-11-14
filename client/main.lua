local Blips = {}

lib.locale()

Citizen.CreateThread(function()
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

RegisterNetEvent('bryan_airdrop:client:startGroundCheck', function(airdropId, airdropNetId)
    local object = NetworkGetEntityFromNetworkId(airdropNetId)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(10)

            if not DoesEntityExist(object) then
                TriggerServerEvent('bryan_airdrops:server:changeGroundCheckPlayer', airdropId)
                break
            end

            if GetEntityHeightAboveGround(object) <= 1.0 then
                PlaceObjectOnGroundProperly(object)
                TriggerServerEvent('bryan_airdrops:server:airdropLanded', airdropId)
                break
            end
        end
    end)
end)

RegisterNetEvent('bryan_airdrop:client:prepareAirdropForClient', function(airdropId, airdropNetId)
    exports['ox_target']:addEntity(airdropNetId, {
        {
            name = 'bryan_airdrop:collect',
            label = locale('collect_airdrop'),
            icon = 'fa-solid fa-parachute-box',
            iconColor = '#5BC687',
            distance = 3.0,
            serverEvent = 'bryan_airdrops:server:collectAirdrop',
            airdropId = airdropId
        },
    })
end)

RegisterNetEvent('bryan_airdrop:client:removeAirdropTarget', function(airdropNetId)
    exports['ox_target']:removeEntity(airdropNetId, 'bryan_airdrop:collect')
end)

lib.callback.register('bryan_airdrop:client:getPlate', function()
    return _GeneratePlate()
end)

RemoveBlips = function(airdropId)
    for k, v in ipairs(Blips) do
        if not airdropId or (airdropId and v.airdropId == airdropId) then
            RemoveBlip(v.blip)
            table.remove(Blips, k)
        end
    end
end