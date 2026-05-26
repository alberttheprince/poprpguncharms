local Config = require 'config'

local function setFlagViaCallback(flagId)
    local ok, err = lib.callback.await('flag_charms:setFlag', false, flagId)
    if not ok then
        lib.notify({ title = 'Flag', description = err or 'Failed', type = 'error' })
        return false
    end
    if flagId then
        local cfg = Config.Flags[flagId]
        lib.notify({
            title       = 'Flag',
            description = 'Equipped: ' .. ((cfg and cfg.label) or flagId),
            type        = 'success',
        })
    else
        lib.notify({ title = 'Flag', description = 'Removed', type = 'inform' })
    end
    return true
end

local function toggleFlag()
    local ok, result = lib.callback.await('flag_charms:toggleFlag', false)
    if not ok then
        lib.notify({
            title       = 'Flag',
            description = result or 'No flag available',
            type        = 'error',
        })
        return
    end

    if result then
        local cfg = Config.Flags[result]
        lib.notify({
            title       = 'Flag',
            description = 'Equipped: ' .. ((cfg and cfg.label) or result),
            type        = 'success',
        })
    else
        lib.notify({ title = 'Flag', description = 'Removed', type = 'inform' })
    end
end

local function openPicker(overrideCurrent)
    local available = lib.callback.await('flag_charms:getAvailableFlags', false)
    if not available or #available == 0 then
        lib.notify({ title = 'Flag', description = 'No flags configured', type = 'inform' })
        return
    end

    local current
    if overrideCurrent == false then
        current = nil
    elseif overrideCurrent ~= nil then
        current = overrideCurrent
    else
        current = LocalPlayer.state.flagCharm
    end

    local options = {}

    if current then
        options[#options + 1] = {
            title       = 'Remove current flag',
            description = (Config.Flags[current] and Config.Flags[current].label) or current,
            icon        = 'xmark',
            onSelect    = function()
                if setFlagViaCallback(false) then
                    openPicker(false)
                end
            end,
        }
    end

    for i = 1, #available do
        local flag = available[i]
        local isCurrent = current == flag.id
        options[#options + 1] = {
            title       = (isCurrent and '✓ ' or '') .. flag.label,
            description = flag.id,
            icon        = 'flag',
            onSelect    = function()
                if setFlagViaCallback(flag.id) then
                    openPicker(flag.id)
                end
            end,
        }
    end

    lib.registerContext({
        id      = 'flag_charms_picker',
        title   = 'Weapon Flags',
        options = options,
    })
    lib.showContext('flag_charms_picker')
end

local function onActivate()
    if Config.UnrestrictedCommandUse then
        openPicker()
    else
        toggleFlag()
    end
end

RegisterNetEvent('flag_charms:toggle', onActivate)
exports('flagAction', onActivate)
exports('openFlagMenu', openPicker)


if not Config.Radial.enabled then return end

local OX_RADIAL_ID = 'flag_charms'
local QB_RADIAL_ID = 'flag_charms_toggle'
local radialAdded  = false

local function addRadial()
    if radialAdded then return end

    if lib and lib.addRadialItem then
        lib.addRadialItem({
            id       = OX_RADIAL_ID,
            label    = Config.Radial.label,
            icon     = Config.Radial.icon,
            onSelect = onActivate,
        })
    end

    if GetResourceState('qb-radialmenu') == 'started' then
        pcall(function()
            exports['qb-radialmenu']:AddOption({
                {
                    id          = QB_RADIAL_ID,
                    title       = Config.Radial.label,
                    icon        = Config.Radial.icon,
                    type        = 'client',
                    event       = 'flag_charms:toggle',
                    shouldClose = true,
                },
            }, QB_RADIAL_ID)
        end)
    end

    radialAdded = true
end

local function removeRadial()
    if not radialAdded then return end

    if lib and lib.removeRadialItem then
        pcall(lib.removeRadialItem, OX_RADIAL_ID)
    end

    if GetResourceState('qb-radialmenu') == 'started' then
        pcall(function()
            exports['qb-radialmenu']:RemoveOption(QB_RADIAL_ID)
        end)
    end

    radialAdded = false
end

local function refreshRadial()
    if Config.UnrestrictedCommandUse then
        if next(Config.Flags) then addRadial() else removeRadial() end
    else
        local groupName = lib.callback.await('flag_charms:getGroup', false)
        if groupName then addRadial() else removeRadial() end
    end
end

local function onGroupChange()
    refreshRadial()
    if not Config.UnrestrictedCommandUse then
        TriggerServerEvent('flag_charms:groupChanged')
    end
end

CreateThread(function()
    Wait(1000)
    refreshRadial()
end)

-- QBX
RegisterNetEvent('qbx_core:client:playerLoaded', refreshRadial)
RegisterNetEvent('qbx_core:client:onGangUpdate', onGroupChange)
RegisterNetEvent('qbx_core:client:onJobUpdate',  onGroupChange)

-- QBCore
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', refreshRadial)
RegisterNetEvent('QBCore:Client:OnGangUpdate',   onGroupChange)
RegisterNetEvent('QBCore:Client:OnJobUpdate',    onGroupChange)

-- ESX
RegisterNetEvent('esx:playerLoaded',             refreshRadial)
RegisterNetEvent('esx:setJob',                   onGroupChange)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        removeRadial()
    end
end)