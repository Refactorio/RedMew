local Event = require 'utils.event'
local Global = require 'utils.global'
local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
local Popup = require 'features.gui.popup'

local floor = math.floor

local players_popuped = {}

Global.register(
    players_popuped,
    function(tbl)
        players_popuped = tbl
    end
)

local rail_entities = {
    ['straight-rail'] = true,
    ['curved-rail'] = true
}

local function all_on_landfill(entity)
    local get_tile = entity.surface.get_tile
    local area = entity.bounding_box
    local left_top = area.left_top
    local right_bottom = area.right_bottom

    for x = floor(left_top.x), floor(right_bottom.x) do
        for y = floor(left_top.y), floor(right_bottom.y) do
            if get_tile(x, y).name ~= 'landfill' then
                return false
            end
        end
    end

    return true
end

RestrictEntities.set_keep_alive_callback(
    function(entity)
        local name = entity.name
        if name == 'entity-ghost' then
            name = entity.ghost_name
        end

        if not rail_entities[name] then
            return true
        end

        return all_on_landfill(entity)
    end
)

-- On first time player places rail entity on invalid tile, show popup explaining the rail mechanic.
local function restricted_entity_destroyed(event)
    local p = event.player
    if not p or not p.valid then
        return
    end

    if players_popuped[p.index] then
        return
    end

    Popup.player(p, 'Rails can only be built on green tiles.', nil, nil, 'rail_grid')
    players_popuped[p.index] = true
end

-- On player join print a notice explaining the rail mechanic
local function player_joined_game(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player or not player.valid then
        return
    end

    player.print(
        "Welcome to RedMew's Rail Grids Map. Rails can only be built on green tiles.",
        {r = 0, g = 1, b = 0, a = 1}
    )
end

Event.add(RestrictEntities.events.on_restricted_entity_destroyed, restricted_entity_destroyed)
Event.add(defines.events.on_player_joined_game, player_joined_game)
