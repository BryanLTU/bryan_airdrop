fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Bryan'
version '1.0.0'
description 'Script that allows Airdrops to fall and players fight over it'

shared_scripts {
    'config.lua',
    '@es_extended/imports.lua',
    '@es_extended/locale.lua',
    'locales/*.lua'
}
client_script 'client.lua'
server_script 'server.lua'

escrow_ignore {
    'config.lua',
    'locales/*.lua'
}