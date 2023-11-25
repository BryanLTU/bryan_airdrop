local Blips, Airdrops = {}, {}

lib.locale()

Citizen.CreateThread(function()
    if Config.Debug then print(string.format('%s Started Successfully | Client Side', GetCurrentResourceName())) end

    local isDisplayingText = false

    while true do
        local sleep = true

        if #Airdrops > 0 then
            local myCoords = GetEntityCoords(PlayerPedId())

            for k, v in ipairs(Airdrops) do
                if DoesEntityExist(v.object) then
                    local airdropCoords = GetEntityCoords(v.object)
                    local isInRadius = #(myCoords - airdropCoords) <= 4.0

                    if isInRadius then
                        sleep = false

                        if Config.CollectionType == 'textui' and not isDisplayingText then
                            isDisplayingText = true
                            _TextUI(true, locale('press_to_pickup'))
                        elseif Config.CollectionType == '3dtext' then
                            _Text3D(airdropCoords, locale('press_to_pickup'))
                        end

                        if IsControlJustPressed(1, 51) then
                            TriggerServerEvent('bryan_airdrops:server:collectAirdrop', { airdropId = v.airdropId })
                            Citizen.Wait(1000)

                            if Config.CollectionType == 'textui' then
                                isDisplayingText = false
                                _TextUI(false)
                            end
                        end
                    elseif Config.CollectionType == 'textui' and isDisplayingText then
                        isDisplayingText = false
                        _TextUI(false)
                    end
                elseif Config.CollectionType == 'textui' then
                    isDisplayingText = false
                    _TextUI(false)
                end
            end
        end

        if sleep then Citizen.Wait(500) end
        Citizen.Wait(0)
    end
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

    AttachEntityToEntity(parachute, vehicle, GetEntityBoneIndexByName(vehicle, 'roof'), 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0, false, false, false, GetEntityRotation(vehicle), true)
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

            if GetEntityHeightAboveGround(object) <= 2.0 then
                PlaceObjectOnGroundProperly(object)
                TriggerServerEvent('bryan_airdrops:server:airdropLanded', airdropId)

                Citizen.Wait(1000)
                FreezeEntityPosition(object, false)

                break
            end
        end
    end)
end)

RegisterNetEvent('bryan_airdrop:client:removeParticles', function(airdropNetId)
    RemoveParticleFxFromEntity(NetworkGetEntityFromNetworkId(airdropNetId))
end)

RegisterNetEvent('bryan_airdrop:client:initializeClientCollect', function(airdropId, airdropNetId)
    if Config.CollectionType == 'target' then
        _AddTarget(airdropId, airdropNetId)
    else
        table.insert(Airdrops, {
            airdropId = airdropId,
            object = NetworkGetEntityFromNetworkId(airdropNetId)
        })
    end
end)

RegisterNetEvent('bryan_airdrop:client:removeClientCollect', function(id)
    if Config.CollectionType == 'target' then
        _RemoveTarget(airdropNetId)
    else
        for k, v in ipairs(Airdrops) do
            if v.airdropId == id then
                table.remove(Airdrops, k)
                break
            end
        end
    end
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