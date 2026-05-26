local Config = require 'config'

local Framework = {}

local function detectFramework()
    if GetResourceState('qbx_core')    == 'started' then return 'qbx' end
    if GetResourceState('qb-core')     == 'started' then return 'qb' end
    if GetResourceState('es_extended') == 'started' then return 'esx' end
    return 'standalone'
end

Framework.name = (not Config.Framework or Config.Framework == 'auto')
    and detectFramework()
    or Config.Framework

print(('^2[flag_charms]^7 framework: %s'):format(Framework.name))

local METADATA_KEY = 'flagCharm'
local KVP_PREFIX   = 'flag_charms:'

-- KVP fallback used for frameworks without native player metadata (ESX, standalone).
local function kvpKey(source)
    return KVP_PREFIX .. (GetPlayerIdentifierByType(source, 'license') or 'unknown')
end

local function kvpSave(source, flagId)
    SetResourceKvp(kvpKey(source), flagId or '')
end

local function kvpRead(source)
    local val = GetResourceKvpString(kvpKey(source))
    if not val or val == '' then return nil end
    return val
end

if Framework.name == 'qbx' then
    Framework.getJob = function(source)
        local player = exports.qbx_core:GetPlayer(source)
        return player and player.PlayerData and player.PlayerData.job or nil
    end
    Framework.getGang = function(source)
        local player = exports.qbx_core:GetPlayer(source)
        return player and player.PlayerData and player.PlayerData.gang or nil
    end
    Framework.saveFlag = function(source, flagId)
        local player = exports.qbx_core:GetPlayer(source)
        if player and player.Functions and player.Functions.SetMetaData then
            player.Functions.SetMetaData(METADATA_KEY, flagId or false)
        end
    end
    Framework.readFlag = function(source)
        local player = exports.qbx_core:GetPlayer(source)
        if not player or not player.PlayerData or not player.PlayerData.metadata then return nil end
        local val = player.PlayerData.metadata[METADATA_KEY]
        if not val or val == false then return nil end
        return val
    end
    Framework.onPlayerLoaded = function(callback)
        AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
            callback(source)
        end)
    end

elseif Framework.name == 'qb' then
    local QBCore = exports['qb-core']:GetCoreObject()
    Framework.getJob = function(source)
        local player = QBCore.Functions.GetPlayer(source)
        return player and player.PlayerData and player.PlayerData.job or nil
    end
    Framework.getGang = function(source)
        local player = QBCore.Functions.GetPlayer(source)
        return player and player.PlayerData and player.PlayerData.gang or nil
    end
    Framework.saveFlag = function(source, flagId)
        local player = QBCore.Functions.GetPlayer(source)
        if player and player.Functions and player.Functions.SetMetaData then
            player.Functions.SetMetaData(METADATA_KEY, flagId or false)
        end
    end
    Framework.readFlag = function(source)
        local player = QBCore.Functions.GetPlayer(source)
        if not player or not player.PlayerData or not player.PlayerData.metadata then return nil end
        local val = player.PlayerData.metadata[METADATA_KEY]
        if not val or val == false then return nil end
        return val
    end
    Framework.onPlayerLoaded = function(callback)
        AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
            callback(source)
        end)
    end

elseif Framework.name == 'esx' then
    local ESX = exports['es_extended']:getSharedObject()
    Framework.getJob = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or not xPlayer.job then return nil end
        return {
            name  = xPlayer.job.name,
            grade = { level = tonumber(xPlayer.job.grade) or 0 },
        }
    end
    Framework.getGang = function(source) return nil end
    Framework.saveFlag = kvpSave
    Framework.readFlag = kvpRead
    Framework.onPlayerLoaded = function(callback)
        AddEventHandler('esx:playerLoaded', function(playerId)
            callback(playerId)
        end)
    end

else
    Framework.getJob  = function() return nil end
    Framework.getGang = function() return nil end
    Framework.saveFlag = kvpSave
    Framework.readFlag = kvpRead
    Framework.onPlayerLoaded = function(callback)
        RegisterNetEvent('flag_charms:clientReady', function()
            callback(source)
        end)
    end
end

return Framework