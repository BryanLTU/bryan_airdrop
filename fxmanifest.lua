fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Bryan'
version '1.1.0'
description 'Script that allows Airdrops to fall and players fight over it'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/*.lua',
}
client_script 'client.lua'
server_script 'server.lua'