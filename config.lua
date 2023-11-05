Config = {}

Config.Locale = 'en' --en/fr/es

-- Default: false | This just prints things in console
Config.Debug = false

Config.ObjectModel = 'prop_drop_armscrate_01'   -- Model to spawn in for the falling object

Config.Cooldown = 10                            -- (Minutes) How long it takes before another airdrop is spawned in

Config.OnlyCommand = false                      -- When enabled airdrops can only be spawned with command

Config.FallSpeed = 1                            -- How fast the airdrop falls

Config.SpawnOffline = false                     -- Should airdrops spawn when there're no players online

Config.RemovePreviousAirdrops = false           -- Should all previous airdrops be removed when a new airdrop is spawned

Config.Blip = false                             -- Blip will be displayed in exact location of the airdrop

Config.Radius = true                            -- Radius will be displayed around the area of the airdrop

Config.Command = {
    Enabled         = true,                     -- Is Command enabled
    Name            = 'airdrop',                -- Command Name
    Groups          = { 'group.admin' },        -- Groups that are allowed to execute the command
    ExecutorCoords  = true,                     -- Should airdrop spawn on player's, who executed the command, coordinates 
    ResetCooldown   = false,                    -- Should command execution restart global cooldown on airdrop spawn
}

-- Locations of where the Airdrops can spawn
Config.Locations = {
    vector3(-55.02, -1764.84, 200.0),
    vector3(-93.91, -1749.73, 200.0),
    vector3(-139.08, -1712.92, 200.0)
}

-- Loot Table is chosen randomly, unless admin spawns it with specific ID. If randomly chosen Loot Table doesn't meet chance %, the script will automatically try to select other Loot Table
Config.LootTables = {
    {
        id = 1,             -- Id of the Loot Table
        chance = 100,       -- Chance this Loot Table will be selected
        type = 'items',     -- Type of airdrop (Supported: items, vehicle)
        items = {           -- List of items that are received
            { name = 'bread', count = 3, type = 'item' },
            { name = 'WEAPON_APPISTOL', count = 1, type = 'weapon' },
            { name = 'money', count = 5000, type = 'account' },
        }
    },
    {
        id = 2,
        chance = 5,
        type = 'vehicle',
        vehicle = 'adder'   -- Vehicle model
    }
}

-- Functions
Config.Notification = function(msg) -- Client Side | Custom Notification if You want | By Default: ESX Notification
    TriggerEvent('esx:showNotification', msg)
end

Config.ProgressBar = function(msg, time) -- Client Side | Custom Progress Bar | This function can return true (Airdrop will be looted) or false (Airdrop won't be looted)
    Citizen.Wait(1000)

    return true
end

Config.NotifyPlayers = function(msg, coords) -- Server Side | Should be perhaps some kind of email to the player's phone | For testing it is made as Default ESX Notification
    TriggerClientEvent('esx:showNotification', -1, msg)
end

Config.NotifyExecute = function(playerId, xPlayer) -- Server Side | This function is triggered when someone spawn in airdrop through command | You can add logs for example here and get identifier, name from playerId or xPlayer

end