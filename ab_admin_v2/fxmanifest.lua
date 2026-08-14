fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'KinggABod'
description 'AB Admin — MDT-style admin & moderation panel'
version '2.0.0'

shared_script 'config.lua'

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'oxmysql',
    'qb-core',
    'qb-radialmenu'
}
