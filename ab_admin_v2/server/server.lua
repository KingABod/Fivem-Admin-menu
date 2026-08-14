local QBCore = exports['qb-core']:GetCoreObject()

-----------------------------------------------------------
-- Helpers
-----------------------------------------------------------

local function isWhitelisted(src)
    local pd = QBCore.Functions.GetPlayer(src)
    if not pd then return false end

    local ID = pd.PlayerData.license
    for _, whitelistedID in ipairs(Config.AdminSystem) do
        if whitelistedID == ID then
            return true
        end
    end
    return false
end

local function GetAdminName(src)
    local pd = QBCore.Functions.GetPlayer(src)
    if not pd then return 'Unknown' end
    return pd.PlayerData.charinfo.firstname .. ' ' .. pd.PlayerData.charinfo.lastname
end

local function GetBanDate(banTimestamp)
    if not banTimestamp or banTimestamp == 0 then
        return "N/A"
    else
        return os.date("%b %d, %Y, %I:%M %p", banTimestamp)
    end
end

local function GetExpiredDate(expireTime)
    if expireTime == 0 then
        return "N/A"
    else
        return os.date("%b %d, %Y, %I:%M %p", expireTime)
    end
end

local function GetBanLabel(duration)
    for _, v in ipairs(Config.Bans) do
        if v.value == duration then
            return v.label
        end
    end
    return "Unknown Duration"
end

local function GetTimeRemaining(expireTime)
    if expireTime == 0 then return "Never" end

    local timeLeft = expireTime - os.time()
    if timeLeft <= 0 then return "Expired" end

    local years = math.floor(timeLeft / 31536000)
    local days = math.floor((timeLeft % 31536000) / 86400)
    local hours = math.floor((timeLeft % 86400) / 3600)
    local minutes = math.floor((timeLeft % 3600) / 60)
    local seconds = math.floor(timeLeft % 60)

    local timeString = ""
    if years > 0 then timeString = timeString .. years .. "y " end
    if days > 0 then timeString = timeString .. days .. "d " end
    if hours > 0 then timeString = timeString .. hours .. "h " end
    if minutes > 0 then timeString = timeString .. minutes .. "m " end
    if seconds > 0 or timeString == "" then
        timeString = timeString .. seconds .. "s"
    end

    return timeString
end

local function LogAction(adminName, action, target, detail)
    MySQL.Async.execute('INSERT INTO ' .. Config.LogTable .. ' (admin, action, target, detail, date) VALUES (?, ?, ?, ?, ?)', {
        adminName, action, target, detail, os.time()
    })
end

-----------------------------------------------------------
-- Ban check on connect (unchanged behaviour, adaptive card)
-----------------------------------------------------------

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local src = source
    local identifier = GetPlayerIdentifierByType(src, 'license')
    deferrals.defer()

    deferrals.update("Information verification... Checking identifier")
    Wait(900)

    MySQL.Async.fetchAll('SELECT reason, expire, date FROM ' .. Config.BanTable .. ' WHERE license = ?', {identifier}, function(result)
        if result[1] then
            local expireTime = tonumber(result[1].expire)
            local banTimestamp = tonumber(result[1].date)
            local reason = result[1].reason
            local currentTime = os.time()

            if expireTime == 0 or expireTime > currentTime then
                local isPresenting = true

                CreateThread(function()
                    while isPresenting do
                        local now = os.time()

                        if expireTime ~= 0 and expireTime <= now then
                            isPresenting = false
                            MySQL.Async.execute('DELETE FROM ' .. Config.BanTable .. ' WHERE license = ?', {identifier})
                            deferrals.done()
                            break
                        end

                        local timeRemaining = GetTimeRemaining(expireTime)
                        local banDate = GetBanDate(banTimestamp)
                        local expireDate = GetExpiredDate(expireTime)
                        local text = (expireTime == 0 and "This ban has no expiration date or specific end time. If you have any questions, please contact the server administrators or managers via Discord." or "Please contact the administrators or managers of this server if you have any questions via Discord.")
                        local banText = "You have been " .. (expireTime == 0 and "permanently" or "temporarily") .. " banned from this server."

                        local card = {
                            ["type"] = "AdaptiveCard",
                            ["version"] = "1.3",
                            ["body"] = {
                                {
                                    ["type"] = "TextBlock",
                                    ["text"] = "You are banned!",
                                    ["weight"] = "Bolder",
                                    ["size"] = "ExtraLarge",
                                    ["color"] = "Attention"
                                },
                                {
                                    ["type"] = "TextBlock",
                                    ["text"] = banText,
                                    ["wrap"] = true
                                },
                                {
                                    ["type"] = "FactSet",
                                    ["facts"] = {
                                        { ["title"] = "Ban Reason:", ["value"] = reason },
                                        { ["title"] = "Ban Date:", ["value"] = banDate },
                                        { ["title"] = "Expires on:", ["value"] = expireDate },
                                        { ["title"] = "Remaining:", ["value"] = timeRemaining }
                                    }
                                },
                                {
                                    ["type"] = "TextBlock",
                                    ["text"] = text,
                                    ["wrap"] = true,
                                    ["spacing"] = "Medium"
                                }
                            },
                            ["actions"] = {
                                {
                                    ["type"] = "Action.OpenUrl",
                                    ["title"] = "Discord",
                                    ["url"] = Config.Discord
                                }
                            }
                        }

                        deferrals.presentCard(card)

                        if expireTime == 0 then
                            Wait(10000)
                        else
                            Wait(1000)
                        end
                    end
                end)
            else
                MySQL.Async.execute('DELETE FROM ' .. Config.BanTable .. ' WHERE license = ?', {identifier})
                deferrals.done()
            end
        else
            deferrals.done()
        end
    end)
end)

-----------------------------------------------------------
-- Panel data feeds
-----------------------------------------------------------

RegisterNetEvent('ab_admin:server:GetPlayers', function()
    local src = source
    if not isWhitelisted(src) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error')
        return
    end

    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        local p = QBCore.Functions.GetPlayer(pid)
        if p then
            local ped = GetPlayerPed(playerId)
            local coords = ped and ped ~= 0 and GetEntityCoords(ped) or nil

            players[#players + 1] = {
                id = pid,
                name = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname,
                license = p.PlayerData.license,
                citizenid = p.PlayerData.citizenid,
                job = p.PlayerData.job and p.PlayerData.job.label or 'Unemployed',
                onDuty = p.PlayerData.job and p.PlayerData.job.onduty or false,
                gender = p.PlayerData.charinfo.gender,
                ping = GetPlayerPing(playerId),
                coords = coords and { x = coords.x, y = coords.y, z = coords.z } or nil
            }
        end
    end
    TriggerClientEvent('ab_admin:client:OpenMenu', src, players)
end)

RegisterNetEvent('ab_admin:server:GetBans', function()
    local src = source
    if not isWhitelisted(src) then return end

    MySQL.Async.fetchAll('SELECT license, reason, admin, expire, date FROM ' .. Config.BanTable .. ' ORDER BY date DESC', {}, function(result)
        local bans = {}
        for _, row in ipairs(result or {}) do
            local expireTime = tonumber(row.expire)
            bans[#bans + 1] = {
                license = row.license,
                reason = row.reason,
                admin = row.admin,
                expire = expireTime,
                date = tonumber(row.date),
                banDate = GetBanDate(tonumber(row.date)),
                expireDate = GetExpiredDate(expireTime),
                remaining = GetTimeRemaining(expireTime),
                permanent = expireTime == 0
            }
        end
        TriggerClientEvent('ab_admin:client:SetBans', src, bans)
    end)
end)

RegisterNetEvent('ab_admin:server:GetLogs', function()
    local src = source
    if not isWhitelisted(src) then return end

    MySQL.Async.fetchAll('SELECT admin, action, target, detail, date FROM ' .. Config.LogTable .. ' ORDER BY id DESC LIMIT 50', {}, function(result)
        TriggerClientEvent('ab_admin:client:SetLogs', src, result or {})
    end)
end)

-----------------------------------------------------------
-- Actions
-----------------------------------------------------------

RegisterNetEvent('ab_admin:server:SendDM', function(targetId, message)
    local src = source
    if not isWhitelisted(src) or not QBCore.Functions.GetPlayer(targetId) then return end

    TriggerClientEvent('ab_admin:client:ReceiveDM', targetId, message)
    TriggerClientEvent('ab_admin:client:Notify', src, 'primary', 'Message sent to ID: ' .. targetId)
    LogAction(GetAdminName(src), 'Message', 'ID ' .. targetId, message)
end)

RegisterNetEvent('ab_admin:server:BanPlayer', function(targetId, reason, duration)
    local src = source
    if not isWhitelisted(src) or not QBCore.Functions.GetPlayer(targetId) then return end

    local identifier = GetPlayerIdentifierByType(targetId, 'license')
    local expireTime = duration > 0 and (os.time() + (duration * 60)) or 0
    local banTime = os.time()
    local adminName = GetAdminName(src)

    MySQL.Async.execute('INSERT INTO ' .. Config.BanTable .. ' (license, reason, admin, expire, date) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE reason = VALUES(reason), admin = VALUES(admin), expire = VALUES(expire), date = VALUES(date)', {
        identifier, reason, adminName, expireTime, banTime
    }, function(rows)
        if rows > 0 then
            TriggerClientEvent('ab_admin:client:Notify', src, 'primary', 'Player Banned Successfully')
            LogAction(adminName, 'Ban', 'ID ' .. targetId, reason .. ' (' .. GetBanLabel(duration) .. ')')

            local kickMessage
            if expireTime == 0 then
                kickMessage = '[Admin Menu] You have been permanently banned for "' .. reason .. '". There is no expiration date for this ban.'
            else
                local expireDate = GetExpiredDate(expireTime)
                local banLabel = GetBanLabel(duration)
                kickMessage = '[Admin Menu] You have been temporarily banned from this server for "' .. reason .. '".\nYour ban will expire in: ' .. expireDate .. ' (' .. banLabel .. ')'
            end
            DropPlayer(targetId, kickMessage)
        end
    end)
end)

RegisterNetEvent('ab_admin:server:UnbanPlayer', function(license)
    local src = source
    if not isWhitelisted(src) or not license then return end

    MySQL.Async.execute('DELETE FROM ' .. Config.BanTable .. ' WHERE license = ?', {license}, function(rows)
        if rows > 0 then
            TriggerClientEvent('ab_admin:client:Notify', src, 'primary', 'Ban lifted')
            LogAction(GetAdminName(src), 'Unban', license, 'Ban record removed')
        else
            TriggerClientEvent('ab_admin:client:Notify', src, 'error', 'No matching ban found')
        end

        MySQL.Async.fetchAll('SELECT license, reason, admin, expire, date FROM ' .. Config.BanTable .. ' ORDER BY date DESC', {}, function(result)
            local bans = {}
            for _, row in ipairs(result or {}) do
                local expireTime = tonumber(row.expire)
                bans[#bans + 1] = {
                    license = row.license,
                    reason = row.reason,
                    admin = row.admin,
                    expire = expireTime,
                    date = tonumber(row.date),
                    banDate = GetBanDate(tonumber(row.date)),
                    expireDate = GetExpiredDate(expireTime),
                    remaining = GetTimeRemaining(expireTime),
                    permanent = expireTime == 0
                }
            end
            TriggerClientEvent('ab_admin:client:SetBans', src, bans)
        end)
    end)
end)

RegisterNetEvent('ab_admin:server:SendNotify', function(targetId, message, ntype)
    local src = source
    if not isWhitelisted(src) or not QBCore.Functions.GetPlayer(targetId) then return end

    TriggerClientEvent('QBCore:Notify', targetId, message, ntype)
    TriggerClientEvent('ab_admin:client:Notify', src, 'primary', 'Notification sent')
    LogAction(GetAdminName(src), 'Notify', 'ID ' .. targetId, message)
end)
