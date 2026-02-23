-- Damages players while walking on ores
-- source: https://mods.factorio.com/mod/Krastorio2
-- author: Raiguard
-- modified by RedRafe
-- ============================================================================

local Event = require 'utils.event'
local Global = require 'utils.global'
local math_floor = math.floor

---@class RadioactivityPlayerData
---@field entity boolean
---@field last_position MapPosition
---@field alert string

---@type table<uint, RadioactivityPlayerData>
local tracked_players = {} --[[as [player_index] --> RadioactivityPlayerData]]
Global.register(tracked_players, function(tbl) tracked_players = tbl end)

local UPDATE_INTERVAL = 20
local DAMAGE = 6.5 * UPDATE_INTERVAL / 60
local search_filter = { radius = 3, name = {}, position = nil }
do
    local resources = prototypes.get_entity_filtered{{ filter = 'type', type = 'resource' }}
    for name in pairs(resources) do
        table.insert(search_filter.name, name)
    end
end

local alerts = {
    'Ouch! Toxic ore struck!',
    'Warning! Hazardous ore!',
    'Ore danger! Take cover!',
    'Ouch! Poisonous touch!',
    'Alert! Toxic mineral!',
    'Danger! Corrosive ore!',
    'Damage! Hazardous contact!',
    'Warning! Deadly ore!',
    'Ouch! Venomous ore!',
    'Alert! Toxic hit!',
    'Danger! Risky ore!',
    'Ouch! Corrosive touch!',
    'Warning! Harmful ore!',
    'Ouch! Radioactive ore!',
    'Alert! Venomous mineral!',
    'Danger! Toxic exposure!',
    'Ouch! Poisoned contact!',
    'Warning! Hazardous mineral!',
    'Damage! Toxic zone!',
    'Ouch! Deadly mineral!',
}

--- Test if two positions are equal
---@param pos1 MapPosition
---@param pos2 MapPosition
---@return boolean
local function position_equal(pos1, pos2)
    local x1 = pos1.x or pos1[1]
    local y1 = pos1.y or pos1[2]
    local x2 = pos2.x or pos2[1]
    local y2 = pos2.y or pos2[2]
    return x1 == x2 and y1 == y2
end

--- Floor the given position
---@param pos MapPosition
---@return MapPosition
local function position_floor(pos)
    if pos.x then
        return { x = math_floor(pos.x), y = math_floor(pos.y) }
    else
        return { math_floor(pos[1]), math_floor(pos[2]) }
    end
end

local function check_around_player(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    local player_data = tracked_players[player.index]
    if not player_data then
        return
    end

    if not (player.character and player.character.valid) then
        player_data.entity = false
        return
    end

    local position = position_floor(player.physical_position)
    local last_position = player_data.last_position
    if position_equal(position, last_position) then
        return
    end
    player_data.last_position = position

    search_filter.position = position
    player_data.entity = player.physical_surface.count_entities_filtered(search_filter) > 0
end

local function update_and_damage()
    for player_index, player_data in pairs(tracked_players) do
        if not player_data.entity then
            goto continue
        end

        local player = game.get_player(player_index)
        if not player or not player.connected or not player.character then
            goto continue
        end

        player.add_custom_alert(player.character, { type = 'virtual', name = 'signal-skull' }, player_data.alert, false)

        -- Damage the player
        player.character.damage(DAMAGE, 'enemy', 'poison')

        ::continue::
    end
end

local function on_player_created(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    tracked_players[player.index] = {
        entity = false,
        last_position = { x = 0, y = 0 },
        alert = alerts[math.random(#alerts)],
    }
end

local function on_player_removed(event)
    tracked_players[event.player_index] = nil
end

Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_player_removed, on_player_removed)

Event.add(defines.events.on_player_changed_position, check_around_player)
Event.add(defines.events.on_player_changed_surface, check_around_player)
Event.add(defines.events.on_player_died, check_around_player)
Event.add(defines.events.on_player_respawned, check_around_player)
Event.add(defines.events.on_player_toggled_map_editor, check_around_player)

Event.on_nth_tick(UPDATE_INTERVAL, update_and_damage)
