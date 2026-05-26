local Config = require 'config'

if Config.Commands.toggle then
    RegisterCommand(Config.Commands.toggle, function(_, args)
        local flagId = args[1]

        if flagId then
            local ok, err = lib.callback.await('flag_charms:setFlag', false, flagId)
            if ok then
                local cfg = Config.Flags[flagId]
                lib.notify({
                    title       = 'Flag',
                    description = 'Equipped: ' .. ((cfg and cfg.label) or flagId),
                    type        = 'success',
                })
            else
                lib.notify({ title = 'Flag', description = err or 'Failed', type = 'error' })
            end
            return
        end

        TriggerEvent('flag_charms:toggle')
    end, false)
end

if Config.Commands.detach then
    RegisterCommand(Config.Commands.detach, function()
        local ok = lib.callback.await('flag_charms:detach', false)
        if ok then
            lib.notify({ title = 'Flag', description = 'Removed', type = 'inform' })
        end
    end, false)
end