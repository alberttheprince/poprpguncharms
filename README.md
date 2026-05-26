# flag_charms

Configurable weapon flag/charm attachment for FiveM. Drops on top of QBox, QBCore, ESX, or standalone setups.

## Features

- 36 banner flag slots pre-configured (`banner_small_flag_01` … `banner_small_flag_36`); add anything else via config
- Per-flag offset, rotation, bone, and label
- Job / gang / grade restrictions per flag (or `anyone = true` for open access)
- "Unrestricted" global mode for non-serious / PVP servers — anyone can `/flag <id>`
- ox_inventory item integration: define `item = 'item_name'` on a flag and using that item toggles it on/off
- Both ox_lib radial and qb-radialmenu pickers
- Server export for auto-attach (PVP team systems, admin tools, etc.)
- State-bag based sync — every client renders the prop on their own local weapon entity, so it shows correctly for all observers

## Installation

1. Drop `flag_charms` into your resources folder
2. Ensure `ox_lib` is started before this resource
3. `ensure flag_charms` in your server.cfg
4. (Optional) Add ox_inventory items if you want item-triggered flags

## Commands

| Command | Description |
|---|---|
| `/flag <id>` | Equip a flag by id (e.g. `/flag banner_small_flag_05`) |
| `/flagoff` | Remove the current flag |
| `/flags` | Open a menu of flags you're allowed to equip |

Command names are configurable; set any to `false` to disable.

## Radial menus

Both pickers are auto-detected. If `ox_lib`'s radial UI is in use, an entry shows up there. If `qb-radialmenu` is started, an entry is added to it as well. Either one opens the same flag picker context menu.

## ox_inventory items

Add a flag entry with an `item` field:

```lua
['banner_small_flag_15'] = {
    label = 'Pirate Banner',
    restrictions = { anyone = true },
    item = 'banner_pirate',
},
```

Then in your ox_inventory items file:

```lua
['banner_pirate'] = {
    label = 'Pirate Banner',
    weight = 100,
    stack  = false,
    consume = 0, -- keep on use; set to 1 if you want one-time charms
},
```

Using the item toggles the flag on/off. Item possession bypasses restrictions.

## Auto-attach via export (PVP team example)

```lua
-- In your team-assignment resource
local function onTeamJoin(playerId, teamColor)
    local flagByTeam = {
        red  = 'banner_small_flag_01',
        blue = 'banner_small_flag_02',
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
| `AttachFlag` | `source, flagId` | `true \| false, err` — bypasses restrictions |
| `DetachFlag` | `source` | `true` |
| `GetPlayerFlag` | `source` | `flagId \| nil` |
| `CanPlayerUse` | `source, flagId` | `true \| false, err` — respects restrictions |

Client-side export:

| Export | Returns |
|---|---|
| `getFlag` | `flagId \| nil` (the local player's current flag) |

## Configuration

See `config.lua` for full field documentation. Quick reference:

```lua
['banner_small_flag_05'] = {
    label  = 'Ballas Banner',
    offset = vec3(0.0, 0.05, 0.0),
    rot    = vec3(0.0, 0.0, 90.0),
    bone   = 'WAPClip',          -- override default bone
    restrictions = {
        gangs  = { 'ballas' },
        grades = { ballas = 2 }, -- minimum grade
    },
    item = 'banner_ballas',
},
```

Set `Config.UnrestrictedCommandUse = true` to ignore all restrictions for command-based use (items and exports are independent of this).

## Notes on bones

`WAPClip` is the magazine attachment point and exists on most rifles, SMGs, and many pistols. For melee or special weapons, set a per-flag `bone` override. If a flag is equipped but the current weapon doesn't have the bone, the prop simply doesn't render — it'll appear when the player swaps to a compatible weapon.

## License

GPL-3.0 (matches the back-items reference this resource was inspired by).
