fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'popcornrp'
description 'Configurable weapon flag/charm attachment with framework support'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua',
    'client/menu.lua',
    'client/commands.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'config.lua',
    'client/framework.lua',
    'server/framework.lua',
}

dependencies {
    'ox_lib',
}
