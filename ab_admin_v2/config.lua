Config = {}

Config.Discord = "discord.gg/put_your_server_invite_url_here"

Config.BanTable = 'ab_bans'
Config.LogTable = 'ab_admin_logs'

Config.UseAnimation = true

Config.Messages = {
    Tx = 'Server Admin',
}

Config.Command = {
    Enable = true,
    UseRadial = true,
    Command = 'ban'
}

-- Shown in the panel header
Config.UI = {
    Title = 'AB ADMIN',
    Subtitle = 'Moderation Terminal',
}

Config.AdminSystem = {
    "license:xxxxxxxxxThisIsNotRealLicensexxxxxxxxxx"
}

Config.Bans = {
    { label = '2 HOURS',   value = 120 },
    { label = '8 HOURS',   value = 480 },
    { label = '1 DAY',     value = 1440 },
    { label = '2 DAYS',    value = 2880 },
    { label = '1 WEEK',    value = 10080 },
    { label = '2 WEEKS',   value = 20160 },
    { label = 'Permanent', value = 0 },
}
