<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/08fdc16b-97c0-4a2a-8578-534ee288e2e1" />


Configurable weapon flag/charm attachment for FiveM. Works with QBox, QBCore, ESX, and standalone setups.

## Features

- Multi-framework: QBox (`qbx_core`), QBCore (`qb-core`), ESX (`es_extended`), or standalone.
- Flags exclusive to gang or jobs: being in the group is what unlocks the flag
- Per-weapon-group prop overrides (e.g. small flag on pistols, big flag on rifles, hidden on melee)
- Per-specific-weapon overrides for oddly-shaped guns
- Server-wide defaults via `Config.GlobalPerGroup` and `Config.GlobalPerWeapon`
- Persistence: flag state is saved even when disconnected via KVP
- Auto-clears the flag when a player leaves the matching gang/job
- "Unrestricted" mode for non-RP/PVP servers: anyone can pick any flag from a context menu, with 36 smart banner entries pre-populated (each auto-swaps small/big variants based on weapon class)
- Both ox_lib radial and qb-radialmenu support: the radial dynamically appears/disappears based on group eligibility
- Server export for auto-attach (PVP team systems, admin tools, etc.)
- State-bag based sync: every client renders the prop on their own local weapon entity, so other players see it correctly

## Installation

1. Drop `poprpguncharm` into your resources folder
2. Ensure `ox_lib` is started before this resource
3. `ensure poprpguncharm` in your `server.cfg` (or any other gun charm assets)
4. `ensure poprpguncharms` in your `server.cfg`

## Two modes

**Restricted** (`Config.UnrestrictedCommandUse = false`, default)

- Radial only appears for players whose gang or job matches a key in `Config.Flags`
- Selecting the radial directly toggles their group's flag on/off
- Joining/leaving a gang or job adds/removes the radial entry automatically (no relog needed)
- Leaving the group while wearing the flag auto-clears it

**Unrestricted** (`Config.UnrestrictedCommandUse = true`)

- Radial shows for everyone
- Selecting it opens a context menu of every entry in `Config.Flags`
- Menu stays open between selections so players can flip through options
- Gang/job restrictions are bypassed entirely; keys in `Config.Flags` become arbitrary labels
- Auto-populates 36 banner entries (`banner_01` … `banner_36`) where each entry intelligently uses the small flag prop on pistols/SMGs and the big flag prop on rifles+

## Commands

| Command | Description |
|---|---|
| `/flag` | Toggle your flag (restricted) or open the picker (unrestricted) |
| `/flag <name>` | Equip a specific flag by name (subject to mode rules) |
| `/flagoff` | Remove the current flag |

Command names are configurable in `Config.Commands`; set any to `false` to disable.

## Configuration

Flags are keyed by gang/job name (restricted) or arbitrary label (unrestricted):

```lua
Config.Flags = {
    ['aod'] = {
        label = 'AOD',

        -- Per-weapon-group: swap props and tweak placement by weapon class
        perGroup = {
            pistol  = { model = 'banner_small_flag_13', offset = vec3(0.0, 0.03, -0.04) },
            smg     = { model = 'banner_small_flag_13' },
            rifle   = { model = 'banner_big_flag_13',   offset = vec3(0.0, 0.10, 0.0)  },
            shotgun = { model = 'banner_big_flag_13' },
            sniper  = { model = 'banner_big_flag_13' },
            thrown  = { hide = true },
            melee   = { hide = true },
        },

        -- Per-weapon: fine-tune individual guns (overrides perGroup)
        perWeapon = {
            WEAPON_AK47   = { offset = vec3(0.0, 0.15, 0.02) },
            WEAPON_MUSKET = { model = 'banner_small_flag_13', bone = 'GRIP' },
        },
    },
}
```

Resolution priority (lowest → highest):

1. Flag top-level (`model`, `offset`, `rot`, `bone`)
2. `Config.GlobalPerGroup[group]`
3. flag `perGroup[group]`
4. `Config.GlobalPerWeapon[weapon]`
5. flag `perWeapon[weapon]`

Any layer can set `hide = true` to skip rendering on that weapon. If no `model` resolves for the held weapon, the flag silently doesn't render on it.

Server-wide defaults that apply to every flag:

```lua
Config.GlobalPerGroup = {
    pistol  = { offset = vec3(0.05, 0.0, 0.01) },
    smg     = { offset = vec3(0.18, 0.0, 0.0)  },
    shotgun = { offset = vec3(0.10, 0.0, 0.0)  },
    mg      = { offset = vec3(0.40, 0.0, 0.0)  },
    melee   = { hide = true },
    thrown  = { hide = true },
}

Config.GlobalPerWeapon = {
    -- WEAPON_RAILGUN = { hide = true },
    -- WEAPON_MUSKET  = { offset = vec3(0.0, 0.20, 0.0) },
}
```

## Radial menus

Both ox_lib radial and qb-radialmenu are auto-detected. Whichever is running gets the entry. Set `Config.Radial.enabled = false` to disable.

## Auto-attach via export (PVP team example)

```lua
-- In your team-assignment resource
local function onTeamJoin(playerId, teamColor)
    local flagByTeam = {
        red  = 'aod',
        blue = 'trident',
    }
    exports.flag_charms:AttachFlag(playerId, flagByTeam[teamColor])
end

local function onTeamLeave(playerId)
    exports.flag_charms:DetachFlag(playerId)
end
```

Server-side exports:

| Export | Args | Returns |
|---|---|---|
| `AttachFlag` | `source, flagId` | `true \| false, err` bypasses gang/job check |
| `DetachFlag` | `source` | `true` |
| `GetPlayerFlag` | `source` | `flagId \| nil` |

Client-side export:

| Export | Returns |
|---|---|
| `getFlag` | `flagId \| nil` (the local player's current flag) |

## Notes on bones

`Config.DefaultBone = 'WAPClip'` (the magazine attachment point) works on most rifles, SMGs, and many pistols. Two other useful values:

- `bone = false` (or `Config.DefaultBone = false`): attach to the **weapon entity origin** (bone index 0). Use this when no weapon bone gives you the placement you want, and you'd rather position the flag purely via `offset`. Pairs well with the per-group offsets in `Config.GlobalPerGroup`.
- `bone = 'BoneName'`: attach to a specific named bone on the weapon (e.g. `Gun_Main_Bone`, `WAPClip`, `GRIP`).

Things worth knowing:

- **Bone names are case-sensitive**: `gun_main_bone` won't resolve, but `Gun_Main_Bone` will. Use the exact casing shown in OpenIV / CodeWalker / Blender.
- **Root bones aren't queryable at runtime** : most modern weapon skeletons have a `Gun_Root` bone visible in Blender, but GTA V folds the root into the entity's transform and `GetEntityBoneIndexByName` returns -1 for it. Use `bone = false` if you want that attachment point.
- **Skeletons vary per weapon**: Some weapons don't have bones that others do, and vice versa. If a bone doesn't exist on the currently held weapon, the flag silently doesn't render. It'll appear again when the player swaps to a weapon that does have it.
