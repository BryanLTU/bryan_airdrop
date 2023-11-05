fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Bryan'
version '1.2.0'
description 'Script that allows Airdrops to fall and players fight over it'

files {
    'locales/*.json'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}