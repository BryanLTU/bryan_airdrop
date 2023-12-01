FrameworkObj = nil

if Config.Framework == 'esx' then
    FrameworkObj = exports['es_extended']:getSharedObject()
elseif Config.Framework == 'qbcore' then
    FrameworkObj = exports['qb-core']:GetCoreObject()
end

_Notification = function(msg, type)
    lib.notify({
        title = locale('airdrop'),
        description = msg,
        type = type,
        icon = 'plane-up',
        iconColor = '#18B17E',
    })
end

_TextUI = function(value, msg)
    if value then
        lib.showTextUI(msg, {
            icon = 'parachute-box',
        })
    else
        lib.hideTextUI()
    end
end

_Text3D = function(coords, msg)
    if Config.Framework == 'esx' then
        FrameworkObj.Game.Utils.DrawText3D(coords, msg, 0.8, 4)
    elseif Config.Framework == 'qbcore' then
        FrameworkObj.Functions.DrawText3D(coords.x, coords.y, coords.z, msg)
    end
end

_AddRadius = function(coords)
    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, Config.Radius)
    SetBlipColour(blip, 1)
    SetBlipAlpha(blip, 150)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(locale('airdrop')) 
    EndTextCommandSetBlipName(blip)

    return blip
end

_AddBlip = function(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, 306)
    SetBlipColour(blip, 28)
    SetBlipScale(blip, 0.8)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(locale('airdrop')) 
    EndTextCommandSetBlipName(blip)

    return blip
end

_AddTarget = function(id, netId)
    exports['ox_target']:addEntity(netId, {
        {
            name = 'bryan_airdrop:collect',
            label = locale('collect_airdrop'),
            icon = 'fa-solid fa-parachute-box',
            iconColor = '#5BC687',
            distance = 3.0,
            serverEvent = 'bryan_airdrops:server:collectAirdrop',
            airdropId = id
        },
    })
end

_RemoveTarget = function(netId)
    exports['ox_target']:removeEntity(netId, 'bryan_airdrop:collect')
end

_GeneratePlate = function()
    if Config.Framework == 'esx' then
        return exports['esx_vehicleshop']:GeneratePlate()
    elseif Config.Framework == 'qbcore' then
        -- TODO QB compatibility
    end
end