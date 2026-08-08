```lua
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local src = source
    local identifier = GetPlayerIdentifierByType(src, 'license')
    deferrals.defer()
    
    Wait(0)
    deferrals.update("Information verification... Checking identifier")
    Wait(1000)

    MySQL.Async.fetchAll('SELECT reason, expire, date FROM ' .. Config.BanTable .. ' WHERE license = ?', {identifier}, function(result)
        if result[1] then
            local expireTime = tonumber(result[1].expire)
            local banTimestamp = tonumber(result[1].date)
            local currentTime = os.time()

            if expireTime == 0 or expireTime > currentTime then
                local discordLink = Config.Discord
                
                local banDate = GetBanDate(banTimestamp)
                local expireDate = GetExpiredDate(expireTime)
                local timeString = GetTimeRemaining(expireTime)

                local message = ""

                if expireTime == 0 then
                    message = "You have been permanently banned from this server.\nBan Reason: " .. result[1].reason .. "\nBan Date: " .. banDate .. "\nExpires onN/A\nTime Remaining: N/A\n\nThere is no expiration date or specific date for this ban. Please contact the administrators or managers of this server if you have any questions via Discord: " .. discordLink
                else
                    message = "You have been temporarily banned from this server.\nBan Reason: " .. result[1].reason .. "\nBan Date: " .. banDate .. "\nExpires on: " .. expireDate .. "\nTime Remaining: " .. timeString .. "\n\nPlease contact the administrators or managers of this server if you have any questions via Discord: " .. discordLink
                end

                deferrals.done(message)
            else
                MySQL.Async.execute('DELETE FROM ' .. Config.BanTable .. ' WHERE license = ?', {identifier})
                deferrals.done()
            end
        else
            deferrals.done()
        end
    end)
end)