local Config    = require 'config'
local Framework = require 'server.framework'

local function getPlayerGroup(source)
    local gang = Framework.getGang(source)
    if gang and gang.name and Config.Flags[gang.name] then
        return gang.name
    end
    local job = Framework.getJob(source)
    if job and job.name and Config.Flags[job.name] then
        return job.name
    end
    return nil
end

local function setFlag(source, flagId, bypassCheck)
    if not flagId then
        Player(source).state:set('flagCharm', false, true)
        Framework.saveFlag(source, nil)
        return true
    end

    if not Config.Flags[flagId] then
        return false, 'Unknown flag'
    end

    if not bypassCheck and not Config.UnrestrictedCommandUse then
        if getPlayerGroup(source) ~= flagId then
            return false, 'You do not have permission to use this flag'
        end
    end

    Player(source).state:set('flagCharm', flagId, true)
    Framework.saveFlag(source, flagId)
    return true
end

local function toggleFlag(source)
    if Config.UnrestrictedCommandUse then
        return false, 'Open the menu to pick a flag'
    end

    local groupName = getPlayerGroup(source)
    if not groupName then return false, 'No flag available for your group' end

    local current = Player(source).state.flagCharm
    if current == groupName then
        setFlag(source, nil)
        return true, false
    else
        setFlag(source, groupName)
        return true, groupName
    end
end

local function revalidateFlag(source)
    if Config.UnrestrictedCommandUse then return end

    local current = Player(source).state.flagCharm
    if not current then return end
    if getPlayerGroup(source) ~= current then
        setFlag(source, nil)
    end
end

local function restoreFlag(source)
    local saved = Framework.readFlag(source)
    if not saved then return end
    if not Config.Flags[saved] then
        Framework.saveFlag(source, nil)
        return
    end

    if Config.UnrestrictedCommandUse or getPlayerGroup(source) == saved then
        Player(source).state:set('flagCharm', saved, true)
    else
        Framework.saveFlag(source, nil)
    end
end

--  Events

Framework.onPlayerLoaded(function(source)
    SetTimeout(1500, function() restoreFlag(source) end)
end)

RegisterNetEvent('flag_charms:groupChanged', function()
    revalidateFlag(source)
end)

AddEventHandler('playerDropped', function()
    if source then
        Player(source).state:set('flagCharm', false, true)
    end
end)

--  Callbacks

lib.callback.register('flag_charms:setFlag', function(source, flagId)
    return setFlag(source, flagId, false)
end)

lib.callback.register('flag_charms:toggleFlag', function(source)
    return toggleFlag(source)
end)

lib.callback.register('flag_charms:detach', function(source)
    return setFlag(source, nil)
end)

lib.callback.register('flag_charms:getGroup', function(source)
    return getPlayerGroup(source)
end)

lib.callback.register('flag_charms:getAvailableFlags', function(source)
    if Config.UnrestrictedCommandUse then
        local available = {}
        for key, cfg in pairs(Config.Flags) do
            available[#available + 1] = {
                id    = key,
                label = (cfg and cfg.label) or key,
            }
        end
        table.sort(available, function(a, b) return a.label < b.label end)
        return available
    end

    local groupName = getPlayerGroup(source)
    if not groupName then return {} end
    local cfg = Config.Flags[groupName]
    return { { id = groupName, label = (cfg and cfg.label) or groupName } }
end)

--  Public exports

exports('AttachFlag', function(source, flagId)
    return setFlag(source, flagId, true)
end)

exports('DetachFlag', function(source)
    return setFlag(source, nil)
end)

exports('GetPlayerFlag', function(source)
    return Player(source).state.flagCharm or nil
end)