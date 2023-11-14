_Notification = function(msg, type)
    lib.notify({
        title = locale('airdrop'),
        description = msg,
        type = type,
        icon = 'plane-up',
        iconColor = '#18B17E',
    })
end

_AddRadius = function(coords)
    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, Config.Radius)

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

_LootAirdrop = function()

end

_GeneratePlate = function()
    if Config.Framework == 'esx' then
        return exports['esx_vehicleshop']:GeneratePlate()
    elseif Config.Framework == 'qbcore' then
        -- TODO QB compatibility
    end
end