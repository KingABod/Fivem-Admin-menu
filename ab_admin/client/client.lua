local QBCore = exports['qb-core']:GetCoreObject()
local menuAdded, menuId, tablet = false, nil, false
local tabletDict, tabletAnim = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', 'base'
local tabletProp, tabletBone = `prop_cs_tablet`, 60309
local tabletOffset, tabletRot = vector3(0.03, 0.002, -0.0), vector3(10.0, 160.0, 0.0)

local function Notify(text, type)
    QBCore.Functions.Notify(text, type)
end

local function isWhitelisted()
    local pd = QBCore.Functions.GetPlayerData()
    local ID = pd.license

    for _, whitelistedID in ipairs(Config.AdminSystem) do
        if whitelistedID == ID then
            return true
        end
    end

    return false
end

local function ToggleTablet(toggle)
    if not Config.UseAnimation then return end
    if toggle and not tablet then
        tablet = true
        CreateThread(function()
            RequestAnimDict(tabletDict)
            while not HasAnimDictLoaded(tabletDict) do Wait(1) end
            RequestModel(tabletProp)
            while not HasModelLoaded(tabletProp) do Wait(1) end
            local playerPed = PlayerPedId()
            local tabletObj = CreateObject(tabletProp, 0.0, 0.0, 0.0, true, true, false)
            local tabletBoneIndex = GetPedBoneIndex(playerPed, tabletBone)
            SetCurrentPedWeapon(playerPed, `weapon_unarmed`, true)
            AttachEntityToEntity(tabletObj, playerPed, tabletBoneIndex, tabletOffset.x, tabletOffset.y, tabletOffset.z, tabletRot.x, tabletRot.y, tabletRot.z, true, false, false, false, 2, true)
            SetModelAsNoLongerNeeded(tabletProp)
            while tablet do
                Wait(1)
                playerPed = PlayerPedId()
                if not IsEntityPlayingAnim(playerPed, tabletDict, tabletAnim, 3) then
                    TaskPlayAnim(playerPed, tabletDict, tabletAnim, 3.0, 3.0, -1, 49, 0, 0, 0, 0)
                end
            end
            ClearPedSecondaryTask(playerPed)
            Wait(1)
            DetachEntity(tabletObj, true, false)
            DeleteEntity(tabletObj)
        end)
    elseif not toggle and tablet then
        tablet = false
    end
end

local function manageRadialOption()
    local isAllowed = isWhitelisted()
    
    if isAllowed and not menuAdded then
        menuId = exports['qb-radialmenu']:AddOption({
            id = 'admin_management',
            title = 'System',
            icon = 'building-user',
            type = 'client',
            event = 'ab_admin:client:OpenAdminRadial',
            shouldClose = true
        })
        menuAdded = true
    elseif not isAllowed and menuAdded then
        if menuId then exports['qb-radialmenu']:RemoveOption(menuId) end
        menuAdded, menuId = false, nil
    end
end

CreateThread(function()
    if Config.Command.UseRadial then
        while true do
            manageRadialOption()
            Wait(5000)
        end
    end
end)

RegisterNetEvent('ab_admin:client:OpenAdminRadial', function()
    if isWhitelisted() then
        TriggerServerEvent('ab_admin:server:GetPlayers')
    else
        QBCore.Functions.Notify("You don't have permission to use this action", 'error')
    end
end)

local function GetGenderIcon()
    local PD = QBCore.Functions.GetPlayerData()
    local gender = PD.charinfo.gender
    local icon

    if gender == 1 then 
        icon = 'fa-solid fa-venus'
    elseif gender == 0 or gender == 2 then
        icon = 'fa-solid fa-mars-stroke'
    end

    return icon
end

RegisterNetEvent('ab_admin:client:OpenMenu', function(players)
    local PD = QBCore.Functions.GetPlayerData()
    local options = {}
    for _, player in pairs(players) do

        options[#options + 1] = {
            title = player.name,
            description = "ID: " .. player.id ..  "\nCitizenid: " .. PD.citizenid .. "\n" .. player.license,
            icon = GetGenderIcon(),
            onSelect = function()
                ToggleTablet(true)
                lib.registerContext({
                    id = 'playerMenu_' .. player.id,
                    title = 'Actions',
                    onExit = function() ToggleTablet(false) end,
                    options = {
                        {
                            title = 'Ban Player',
                            icon = 'ban',
                            -- iconColor = '#ff5050',
                            onSelect = function()
                                local input = lib.inputDialog('Ban Player', {
                                    { type = 'input',  label = 'Reason:', required = false, placeholder = 'Spam, Hack, Cheating', icon = 'fa-solid fa-ban', description = 'The message you want to show the player when he is banned' },
                                    { type = 'select', label = 'Duration:', required = false, options = Config.Bans, icon = 'fa-solid fa-hourglass-half', description = 'The length of time the player spends in a ban' }
                                })

                                if not input then
                                    ToggleTablet(false)
                                    return
                                end

                                if not input[1] or input[1] == '' or not input[2] then
                                    Notify('Please complete the data...', 'error')
                                    ToggleTablet(false)
                                    return
                                end

                                local alert = lib.alertDialog({
                                    header = 'Confirm Ban',
                                    content = 'Are you sure you want to ban this player?',
                                    centered = true,
                                    cancel = true,
                                    labels = {
                                        confirm = 'Confirm',
                                        cancel = 'Cancel',
                                        -- iconColor = '#ff5050'
                                    }
                                })

                                if alert == 'confirm' then
                                    TriggerServerEvent('ab_admin:server:BanPlayer', player.id, input[1], tonumber(input[2]))
                                end
                                
                                ToggleTablet(false)
                            end
                        },
                        {
                            title = 'Send txAdmin Message',
                            icon = 'message',
                            -- iconColor = '#40ff96',
                            onSelect = function()
                                local input = lib.inputDialog('txAdmin Message', {
                                    {type = 'input', label = 'Message', required = false, icon = 'fa-solid fa-comment-dots', description = 'Write the message you want to appear to the player' }
                                })

                                if not input then
                                    ToggleTablet(false)
                                    return
                                end

                                if not input[1] or input[1] == '' then
                                    Notify('Please enter a message...', 'error')
                                    ToggleTablet(false)
                                    return
                                end

                                if input then 
                                    TriggerServerEvent('ab_admin:server:SendDM', player.id, input[1]) 
                                end

                                ToggleTablet(false)
                            end
                        },
                        {
                            title = 'Send Notification',
                            icon = 'bell',
                            -- iconColor = '#40a9ff',
                            onSelect = function()
                                local input = lib.inputDialog('Notification', {
                                    {type = 'input', label = 'Message', required = false, icon = 'fa-solid fa-bell', description = 'Write the message you want to appear to the player' },
                                    {type = 'select', label = 'Type', options = { {value = 'error', label = 'Error'}, {value = 'primary', label = 'Primary'} }, required = false, icon = 'fa-solid fa-sort', description = 'Choose the type of alert you want.' }
                                })

                                if not input then
                                    ToggleTablet(false)
                                    return
                                end

                                if not input[1] or input[1] == '' or not input[2] then
                                    ToggleTablet(false)
                                    Notify('Please complete the data...', 'error')
                                    return
                                end

                                if input then 
                                    TriggerServerEvent('ab_admin:server:SendNotify', player.id, input[1], input[2]) 
                                end
                                
                                ToggleTablet(false)
                            end
                        },
                        {
                            title = 'Teleport to Player',
                            icon = 'location-arrow',
                            -- iconColor = '#40f5ff',
                            onSelect = function()
                                local ped = PlayerPedId()
                                if player.coords then
                                    ToggleTablet(false)
                                    DoScreenFadeOut(500)
                                    while not IsScreenFadedOut() do Wait(10) end
                                    
                                    SetEntityCoords(ped, player.coords.x, player.coords.y, player.coords.z, false, false, false, false)
                                    
                                    Wait(500)
                                    DoScreenFadeIn(500)
                                    lib.notify({
                                        title = 'Admin Teleport',
                                        description = 'Teleported to: ' .. player.name,
                                        type = 'success'
                                    }) ToggleTablet(false)
                                else
                                    lib.notify({
                                        title = 'Error',
                                        description = 'Could not get player coordinates',
                                        type = 'error'
                                    }) ToggleTablet(false)
                                end
                            end
                        }
                    }
                })
                lib.showContext('playerMenu_' .. player.id)
            end
        }
    end

    lib.registerContext({ 
        id = 'adminMenu', 
        title = 'Players', 
        options = options,
        onExit = function() ToggleTablet(false) end
    })
    ToggleTablet(true)
    lib.showContext('adminMenu')
end)

if Config.Command.Enable then
    RegisterCommand(Config.Command.Command, function()
        if isWhitelisted() then
            TriggerServerEvent('ab_admin:server:GetPlayers')
        else
            Notify("You don't have permission for use this command", 'error')
        end
    end)

    CreateThread(function()
        Wait(1000)
        TriggerEvent('chat:addSuggestion', '/' .. Config.Command.Command, 'Open Ban Menu')
    end)
end

RegisterNetEvent('ab_admin:client:Notify', function(type, message)
    QBCore.Functions.Notify(message, type)
end)

RegisterNetEvent('ab_admin:client:ReceiveDM', function(message)
    TriggerEvent('txcl:showDirectMessage', message, Config.Messages.Tx)
end)