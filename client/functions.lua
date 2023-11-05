_Notification = function(msg, type)
    ESX.ShowNotification(msg)
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
    AddTextComponentString(locale('blip_name')) 
    EndTextCommandSetBlipName(blip)

    return blip
end

_LootAirdrop = function()

end