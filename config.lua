local Config = {}

-- Default attachment values used when a flag entry doesn't specify its own.
Config.DefaultBone   = false -- False defaults to the center of the gun, DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
Config.DefaultOffset = vec3(0.2, 0.0, 0.0)
Config.DefaultRot    = vec3(0.0, 0.0, 0.0)

-- Framework. 'auto' detects which is running. Override to force a specific one
Config.Framework = 'auto' -- Available frameworks: auto (auto detects framework), qbx (qbx_core), qb (qb-core), esx (es_extended), standalone

-- When true, gang/job restrictions are bypassed; the radial becomes a picker showing every Config.Flags entry. Also enables the auto-fill below.
Config.UnrestrictedCommandUse = true

    Config.Commands = {
        toggle = 'flag',
        detach = 'flagoff',
    }

Config.Radial = {
    enabled = true,
    label   = 'Weapon Flag',
    icon    = 'flag',
}

Config.WeaponGroups = {
    pistol  = `GROUP_PISTOL`,
    smg     = `GROUP_SMG`,
    rifle   = `GROUP_RIFLE`,
    shotgun = `GROUP_SHOTGUN`,
    sniper  = `GROUP_SNIPER`,
    heavy   = `GROUP_HEAVY`,
    mg      = `GROUP_MG`,
    thrown  = `GROUP_THROWN`,
    melee   = `GROUP_MELEE`,
}

Config.GlobalPerGroup = {
    pistol  = {     offset = vec3(0.05, 0.0, 0.01) },
    mg      = {     offset = vec3(0.4, 0.0, 0.00)  },
    smg     = {     offset = vec3(0.18, 0.0, 0.0)  },
    shotgun = {     offset = vec3(0.1, 0.0, 0.0)   },
    melee   = { hide = true },
    thrown  = { hide = true },
    -- pistol  = { bone = 'WAPClip',    offset = vec3(0.0, 0.0, -0.02), rot = vec3(0.0, 0.0, 15.0) },
    -- smg  = { bone = 'WAPClip',    offset = vec3(0.0, 0.0, -0.02), rot = vec3(0.0, 0.0, 15.0) },

}

Config.GlobalPerWeapon = {
    -- WEAPON_MUSKET = { offset = vec3(0.0, 0.20, 0.0) },
}


--  Restriction by gang/job name

Config.Flags = {

    -- ['aod'] = {
    --     label = 'AOD',

    --     perGroup = {
    --         -- rifle   = { model = 'banner_big_flag_17',   offset = vec3(0.2, 0.0, 0.0)  },
    --         pistol  = { model = 'banner_small_flag_13',  },
    --         smg     = { model = 'banner_small_flag_13',  },
    --         heavy   = { model = 'banner_big_flag_13',    },
    --         rifle   = { model = 'banner_big_flag_13',    },
    --         mg   = { model = 'banner_big_flag_13',    },
    --         shotgun = { model = 'banner_big_flag_13',    },
    --         sniper  = { model = 'banner_big_flag_13' },
    --         thrown  = { hide = true },
    --         melee   = { hide = true },
    --     },
    -- },
    -- ['police'] = {
    --     label  = 'Police',
    --     model  = 'banner_small_flag_10',
    --     offset = vec3(0.0, 0.0, 0.0),
    -- },
}

-- Auto-fill banner_01 to _36. One "smart" entry per number that uses the small
-- variant on pistols/SMGs and the big variant on rifles and other long guns. Only runs when
-- UnrestrictedCommandUse is on. Anything explicitly defined above is preserved.
if Config.UnrestrictedCommandUse then
    for i = 1, 36 do
        local key   = ('banner_%02d'):format(i)
        local small = ('banner_small_flag_%02d'):format(i)
        local big   = ('banner_big_flag_%02d'):format(i)

        Config.Flags[key] = Config.Flags[key] or {
            label = ('Banner %02d'):format(i),
            perGroup = {
                pistol  = { model = small },
                smg     = { model = small },
                rifle   = { model = big   },
                shotgun = { model = big   },
                sniper  = { model = big   },
                heavy   = { model = big   },
                mg      = { model = big   },
                thrown  = { hide  = true  },
                melee   = { hide  = true  },
            },
        }
    end
end

return Config