local Blips, Airdrops, AirdropTargets = {}, {}, {}

lib.locale()

Citizen.CreateThread(function()
    if Config.Debug then print(string.format('%s Started Successfully | Client Side', GetCurrentResourceName())) end

    if Config.CollectionType == 'target' then return end

    local isDisplayingText = false

    while true do
        local sleep = true

        if #Airdrops > 0 then
            local myCoords = GetEntityCoords(PlayerPedId())

            for k, v in ipairs(Airdrops) do
                if NetworkDoesNetworkIdExist(v.airdropNetId) then
                    local object = NetworkGetEntityFromNetworkId(v.airdropNetId)

                    if DoesEntityExist(object) then
                        local airdropCoords = GetEntityCoords(object)
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

    RequestNamedPtfxAsset('scr_oddjobtraffickingair')
    while not HasNamedPtfxAssetLoaded('scr_oddjobtraffickingair') do Citizen.Wait(10) end

    UseParticleFxAssetNextCall("scr_oddjobtraffickingair")
    local ptfx = StartNetworkedParticleFxLoopedOnEntity('scr_crate_drop_flare', object, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0)
    SetParticleFxLoopedColour(ptfx, 1.0, 0.0, 0.0, 0)
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
                ApplyForceToEntityCenterOfMass(object, 0, 0.0, 0.0, -1.0, 0, 0, 0, 0)

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
        AddTargetWhenNetIdExists(airdropId, airdropNetId)
    else
        table.insert(Airdrops, {
            airdropId = airdropId,
            airdropNetId = airdropNetId
        })
    end
end)

RegisterNetEvent('bryan_airdrop:client:removeClientCollect', function(airdropId, airdropNetId)
    if Config.CollectionType == 'target' then
        if AirdropTargets[airdropId] then
            _RemoveTarget(airdropNetId)
            AirdropTargets[airdropId] = false
        end
    else
        for k, v in ipairs(Airdrops) do
            if v.airdropId == airdropId then
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

AddTargetWhenNetIdExists = function(airdropId, airdropNetId)
    AirdropTargets[airdropId] = true

    Citizen.CreateThread(function()
        while not NetworkDoesNetworkIdExist(airdropNetId) and AirdropTargets[airdropId] do
            Citizen.Wait(1000)
        end

        if AirdropTargets[airdropId] then
            _AddTarget(airdropId, airdropNetId)
        end
    end)
end