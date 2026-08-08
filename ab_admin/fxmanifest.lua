fx_version 'cerulean'
game 'gta5'
author 'KinggABod'
description 'Admin Menu'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

lua54 'yes'

dependencies {
    'ox_lib',
    'oxmysql',
    'qb-core',
    'qb-radialmenu'
}