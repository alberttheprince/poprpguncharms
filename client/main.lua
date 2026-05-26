local Config    = require 'config'
local Framework = require 'client.framework'

local PlayerState  = LocalPlayer.state
local activeProps  = {}
local attachToken  = {}

local function lookupPerWeapon(perWeapon, weaponHash)
    if not perWeapon then return nil end
    local entry = perWeapon[weaponHash]
    if entry then return entry end
    for k, v in pairs(perWeapon) do
        if type(k) == 'string' and joaat(k) == weaponHash then
            return v
        end
    end
    return nil
end

local function resolveAttachment(flagConfig, weaponHash)
    local resolved = {
        offset = flagConfig.offset or Config.DefaultOffset,
        rot    = flagConfig.rot    or Config.DefaultRot,
        bone   = flagConfig.bone   or Config.DefaultBone,
        model  = flagConfig.model,
        hide   = false,
    }

    local function applyLayer(layer)
        if not layer then return end
        if layer.offset    then resolved.offset = layer.offset end
        if layer.rot       then resolved.rot    = layer.rot    end
        if layer.bone      then resolved.bone   = layer.bone   end
        if layer.model     then resolved.model  = layer.model  end
        if layer.hide ~= nil then resolved.hide = layer.hide   end
    end

    local weaponGroup = GetWeapontypeGroup(weaponHash)
    local groupName
    if Config.WeaponGroups then
        for name, hash in pairs(Config.WeaponGroups) do
            if hash == weaponGroup then
                groupName = name
                break
            end
        end
    end

    if groupName and Config.GlobalPerGroup then
        applyLayer(Config.GlobalPerGroup[groupName])
    end
    if groupName and flagConfig.perGroup then
        applyLayer(flagConfig.perGroup[groupName])
    end

    applyLayer(lookupPerWeapon(Config.GlobalPerWeapon, weaponHash))
    applyLayer(lookupPerWeapon(flagConfig.perWeapon, weaponHash))

    return resolved
end

local function deleteProp(playerId)
    attachToken[playerId] = (attachToken[playerId] or 0) + 1

    local data = activeProps[playerId]
    if not data then return end
    if data.object and DoesEntityExist(data.object) then
        DeleteEntity(data.object)
    end
    activeProps[playerId] = nil
end

local function attachProp(playerId, flagId)
    local flagConfig = Config.Flags[flagId]
    if not flagConfig then return end

    deleteProp(playerId)
    local myToken = attachToken[playerId]
    activeProps[playerId] = { pending = true, flagId = flagId, token = myToken }

    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        if attachToken[playerId] == myToken then activeProps[playerId] = nil end
        return
    end

    local weaponHash = GetSelectedPedWeapon(ped)
    if weaponHash == 0 or weaponHash == `WEAPON_UNARMED` then
        if attachToken[playerId] == myToken then activeProps[playerId] = nil end
        return
    end

    local weapObj = GetCurrentPedWeaponEntityIndex(ped, true)
    if not weapObj or weapObj == 0 or not DoesEntityExist(weapObj) then
        if attachToken[playerId] == myToken then activeProps[playerId] = nil end
        return
    end

    local resolved = resolveAttachment(flagConfig, weaponHash)

    if resolved.hide or not resolved.model then
        if attachToken[playerId] == myToken then activeProps[playerId] = nil end
        return
    end

    local modelHash = type(resolved.model) == 'string' and joaat(resolved.model) or resolved.model

    if not HasModelLoaded(modelHash) then
        local ok = pcall(lib.requestModel, modelHash, 10000)

        if attachToken[playerId] ~= myToken then
            if HasModelLoaded(modelHash) then SetModelAsNoLongerNeeded(modelHash) end
            return
        end

        if not ok or not HasModelLoaded(modelHash) then
            activeProps[playerId] = nil
            lib.print.warn(('Failed to load flag model: %s'):format(resolved.model))
            return
        end
    end

    ped = GetPlayerPed(playerId)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(modelHash)
        if attachToken[playerId] == myToken then activeProps[playerId] = nil end
        return
    end

    weapObj = GetCurrentPedWeaponEntityIndex(ped, true)
    if not weapObj or weapObj == 0 or not DoesEntityExist(weapObj) then
        SetModelAsNoLongerNeeded(modelHash)
        if attachToken[playerId] == myToken then activeProps[playerId] = nil end
        return
    end

    if GetSelectedPedWeapon(ped) ~= weaponHash then
        SetModelAsNoLongerNeeded(modelHash)
        if attachToken[playerId] == myToken then activeProps[playerId] = nil end
        return
    end

    local boneIdx
    if resolved.bone then
        boneIdx = GetEntityBoneIndexByName(weapObj, resolved.bone)
        if boneIdx == -1 then
            SetModelAsNoLongerNeeded(modelHash)
            if attachToken[playerId] == myToken then activeProps[playerId] = nil end
            return
        end
    else
        boneIdx = 0  -- attach to the weapon entity's origin (no specific bone)
    end

    if attachToken[playerId] ~= myToken then
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    local obj = CreateObject(modelHash, 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(modelHash)

    local o = resolved.offset
    local r = resolved.rot

    AttachEntityToEntity(
        obj, weapObj, boneIdx,
        o.x, o.y, o.z,
        r.x, r.y, r.z,
        false, false, false, false, 2, true
    )

    SetEntityNoCollisionEntity(obj,     ped,     false)
    SetEntityNoCollisionEntity(obj,     weapObj, false)
    SetEntityNoCollisionEntity(ped,     obj,     false)
    SetEntityNoCollisionEntity(weapObj, obj,     false)

    activeProps[playerId] = {
        object       = obj,
        weaponEntity = weapObj,
        flagId       = flagId,
    }
end

local function getPlayerFlagState(playerId)
    if playerId == cache.playerId then
        return PlayerState.flagCharm
    end
    local serverId = GetPlayerServerId(playerId)
    if serverId == -1 then return nil end
    return Player(serverId).state.flagCharm
end

AddStateBagChangeHandler('flagCharm', nil, function(bagName, _, value)
    local playerId = GetPlayerFromStateBagName(bagName)
    if not playerId or playerId == 0 then return end

    if not value then
        deleteProp(playerId)
        return
    end

    if playerId ~= cache.playerId and not NetworkIsPlayerActive(playerId) then
        CreateThread(function()
            local timeout = GetGameTimer() + 5000
            while GetGameTimer() < timeout do
                if NetworkIsPlayerActive(playerId) then
                    attachProp(playerId, value)
                    return
                end
                Wait(200)
            end
        end)
        return
    end

    attachProp(playerId, value)
end)

CreateThread(function()
    while true do
        Wait(500)

        for playerId, data in pairs(activeProps) do
            if data.pending then goto continue end

            local ped = GetPlayerPed(playerId)
            if not ped or ped == 0 or not DoesEntityExist(ped)
               or not NetworkIsPlayerActive(playerId) then
                deleteProp(playerId)
            else
                local currentWeapon = GetCurrentPedWeaponEntityIndex(ped, true)
                if not currentWeapon or currentWeapon == 0
                   or not DoesEntityExist(currentWeapon) then
                    deleteProp(playerId)
                elseif data.weaponEntity ~= currentWeapon then
                    attachProp(playerId, data.flagId)
                elseif data.object and DoesEntityExist(data.object)
                       and not IsEntityAttachedToEntity(data.object, currentWeapon) then
                    attachProp(playerId, data.flagId)
                end
            end

            ::continue::
        end

        local activePlayers = GetActivePlayers()
        for i = 1, #activePlayers do
            local playerId = activePlayers[i]
            if not activeProps[playerId] then
                local flagId = getPlayerFlagState(playerId)
                if flagId then attachProp(playerId, flagId) end
            end
        end
    end
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(500)
    local activePlayers = GetActivePlayers()
    for i = 1, #activePlayers do
        local playerId = activePlayers[i]
        local flagId = getPlayerFlagState(playerId)
        if flagId then attachProp(playerId, flagId) end
    end

    -- Standalone has no native player-loaded event server-side; signal here
    -- so the server can run flag restoration. Other frameworks have their
    -- own events and don't need this.
    if Framework.name == 'standalone' then
        Wait(2500)
        TriggerServerEvent('flag_charms:clientReady')
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for playerId in pairs(activeProps) do
        deleteProp(playerId)
    end
end)

AddStateBagChangeHandler('bucket', ('player:%s'):format(cache.serverId), function(_, _, value)
    if value == 0 then
        local flagId = PlayerState.flagCharm
        if flagId then
            CreateThread(function()
                Wait(500)
                deleteProp(cache.playerId)
                attachProp(cache.playerId, flagId)
            end)
        end
    end
end)


--  EXPORTS

exports('getFlag', function()
    return PlayerState.flagCharm or nil
end)