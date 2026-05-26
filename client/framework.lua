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

if Framework.name == 'qbx' then
    Framework.getJob = function()
        local data = exports.qbx_core:GetPlayerData()
        return data and data.job or nil
    end
    Framework.getGang = function()
        local data = exports.qbx_core:GetPlayerData()
        return data and data.gang or nil
    end

elseif Framework.name == 'qb' then
    local QBCore = exports['qb-core']:GetCoreObject()
    Framework.getJob = function()
        local data = QBCore.Functions.GetPlayerData()
        return data and data.job or nil
    end
    Framework.getGang = function()
        local data = QBCore.Functions.GetPlayerData()
        return data and data.gang or nil
    end

elseif Framework.name == 'esx' then
    local ESX = exports['es_extended']:getSharedObject()
    Framework.getJob = function()
        local data = ESX.GetPlayerData()
        if not data or not data.job then return nil end

        return {
            name  = data.job.name,
            grade = { level = tonumber(data.job.grade) or 0 },
        }
    end
    Framework.getGang = function() return nil end

else  -- standalone
    Framework.getJob  = function() return nil end
    Framework.getGang = function() return nil end
end

return Framework