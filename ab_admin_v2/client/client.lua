local QBCore = exports['qb-core']:GetCoreObject()

local menuAdded, menuId = false, nil
local tablet, uiOpen = false, false

local tabletDict, tabletAnim = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', 'base'
local tabletProp, tabletBone = `prop_cs_tablet`, 60309
local tabletOffset, tabletRot = vector3(0.03, 0.002, -0.0), vector3(10.0, 160.0, 0.0)

-----------------------------------------------------------
-- Helpers
-----------------------------------------------------------

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

-----------------------------------------------------------
-- NUI open / close
-----------------------------------------------------------

local function OpenAdminUI(players)
    uiOpen = true
    ToggleTablet(true)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        config = {
            title = Config.UI.Title,
            subtitle = Config.UI.Subtitle,
            discord = Config.Discord,
            bans = Config.Bans,
            command = Config.Command.Command,
        },
        players = players or {}
    })

    CreateThread(function()
        while uiOpen do
            DisableControlAction(0, 1, true)  -- LookLeftRight
            DisableControlAction(0, 2, true)  -- LookUpDown
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 257, true) -- Attack2
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 263, true) -- Melee
            DisableControlAction(0, 288, true) -- Phone
            Wait(0)
        end
    end)
end

local function CloseAdminUI()
    uiOpen = false
    ToggleTablet(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterKeyMapping('closeadminui', 'Close Admin Panel', 'keyboard', 'ESCAPE')

-----------------------------------------------------------
-- Menu triggers (radial + command)
-----------------------------------------------------------

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
        TriggerEvent('chat:addSuggestion', '/' .. Config.Command.Command, 'Open Admin Panel')
    end)
end

-----------------------------------------------------------
-- Server -> Client payload handlers
-----------------------------------------------------------

RegisterNetEvent('ab_admin:client:OpenMenu', function(players)
    if not uiOpen then
        OpenAdminUI(players)
    else
        SendNUIMessage({ action = 'setPlayers', players = players })
    end
end)

RegisterNetEvent('ab_admin:client:SetBans', function(bans)
    SendNUIMessage({ action = 'setBans', bans = bans })
end)

RegisterNetEvent('ab_admin:client:SetLogs', function(logs)
    SendNUIMessage({ action = 'setLogs', logs = logs })
end)

RegisterNetEvent('ab_admin:client:Notify', function(type, message)
    QBCore.Functions.Notify(message, type)
end)

RegisterNetEvent('ab_admin:client:ReceiveDM', function(message)
    TriggerEvent('txcl:showDirectMessage', message, Config.Messages.Tx)
end)

-----------------------------------------------------------
-- NUI Callbacks
-----------------------------------------------------------

RegisterNUICallback('close', function(_, cb)
    CloseAdminUI()
    cb('ok')
end)

RegisterNUICallback('refreshPlayers', function(_, cb)
    TriggerServerEvent('ab_admin:server:GetPlayers')
    cb('ok')
end)

RegisterNUICallback('requestBans', function(_, cb)
    TriggerServerEvent('ab_admin:server:GetBans')
    cb('ok')
end)

RegisterNUICallback('requestLogs', function(_, cb)
    TriggerServerEvent('ab_admin:server:GetLogs')
    cb('ok')
end)

RegisterNUICallback('banPlayer', function(data, cb)
    if data and data.id and data.reason and data.duration ~= nil then
        TriggerServerEvent('ab_admin:server:BanPlayer', tonumber(data.id), data.reason, tonumber(data.duration))
    end
    cb('ok')
end)

RegisterNUICallback('unbanPlayer', function(data, cb)
    if data and data.license then
        TriggerServerEvent('ab_admin:server:UnbanPlayer', data.license)
    end
    cb('ok')
end)

RegisterNUICallback('sendMessage', function(data, cb)
    if data and data.id and data.message and data.message ~= '' then
        TriggerServerEvent('ab_admin:server:SendDM', tonumber(data.id), data.message)
    end
    cb('ok')
end)

RegisterNUICallback('sendNotify', function(data, cb)
    if data and data.id and data.message and data.message ~= '' then
        TriggerServerEvent('ab_admin:server:SendNotify', tonumber(data.id), data.message, data.ntype or 'primary')
    end
    cb('ok')
end)

RegisterNUICallback('teleportToPlayer', function(data, cb)
    local ped = PlayerPedId()
    if data and data.coords then
        DoScreenFadeOut(400)
        local waited = 0
        while not IsScreenFadedOut() and waited < 1000 do Wait(10) waited = waited + 10 end

        SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z, false, false, false, false)

        Wait(400)
        DoScreenFadeIn(400)
        Notify('Teleported to ' .. (data.name or 'player'), 'success')
    else
        Notify('Could not get player coordinates', 'error')
    end
    cb('ok')
end)
