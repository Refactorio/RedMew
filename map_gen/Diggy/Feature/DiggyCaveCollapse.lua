--[[-- info
    Provides the ability to collapse caves when digging.
]]
-- dependencies
require 'utils.list_utils'

local Event = require 'utils.event'
local Template = require 'map_gen.Diggy.Template'
local Debug = require 'map_gen.Diggy.Debug'
local Task = require 'utils.Task'
local Token = require 'utils.global_token'

-- this
local DiggyCaveCollapse = {}

local config = {}

local n = 9
local radius = 0
local radius_sq = 0
local center_radius_sq = 0
local disc_radius_sq = 0

local center_weight
local disc_weight
local ring_weight

local disc_blur_sum = 0

local center_value = 0
local disc_value = 0
local ring_value = 0

local enable_stress_grid = 0
local stress_map_blur_add = nil
local mask_disc_blur = nil
local stress_map_check_stress_in_threshold = nil
local support_beam_entities = nil
local on_surface_created = nil

local stress_threshold_causing_collapse = 0.9

global.deconstruction_alert_message_shown = {}
local deconstruction_alert_message_shown = global.deconstruction_alert_message_shown

global.stress_map_storage = {}
local stress_map_storage = global.stress_map_storage

global.new_tile_map = {}
local new_tile_map = global.new_tile_map

local defaultValue = 0

DiggyCaveCollapse.events = {
    --[[--
        When stress at certain position is above the collapse threshold
         - position LuaPosition
         - surface LuaSurface
    ]]
    on_collapse_triggered = script.generate_event_name()
}

local function create_collapse_template(positions, surface)
    local entities = {}
    local tiles = {}
    local map = {}
    for _, position in pairs(positions) do
        map[position.x] = map[position.x] or {}
        map[position.x][position.y] = map[position.x][position.y] or true
        table.insert(tiles, {position = {x = position.x, y = position.y}, name = 'out-of-map'})
    end

    for x, y_tbl in pairs(map) do
        for y, _ in pairs(y_tbl) do
            if not map[x] or not map[x][y - 1] then
                table.insert(entities, {position = {x = x, y = y - 1}, name = 'sand-rock-big'})
            end
            if not map[x] or not map[x][y + 1] then
                table.insert(entities, {position = {x = x, y = y + 1}, name = 'sand-rock-big'})
            end
            if not map[x - 1] or not map[x - 1][y] then
                table.insert(entities, {position = {x = x - 1, y = y}, name = 'sand-rock-big'})
            end
            if not map[x + 1] or not map[x + 1][y] then
                table.insert(entities, {position = {x = x + 1, y = y}, name = 'sand-rock-big'})
            end
        end
    end

    for _, new_spawn in pairs({entities, tiles}) do
        for _, tile in pairs(new_spawn) do
            for _, entity in pairs(surface.find_entities_filtered({position = tile.position})) do
                pcall(function() entity.die() end)
            end
        end
    end

    return tiles, entities
end

local function collapse(args)
    local position = args.position
    local surface = args.surface
    local positions = {}
    local tiles = {}
    local entities = nil
    mask_disc_blur(
        position.x,  position.y,
        config.collapse_threshold_total_strength,
        function(x, y, value)
            stress_map_check_stress_in_threshold(
                surface,
                {x = x, y = y},
                value,
                function(_, position)
                    table.insert(positions, position)
                end
            )
        end
    )
    tiles, entities = create_collapse_template(positions, surface)
    Template.insert(surface, tiles, entities)
end

local on_collapse_timeout_finished = Token.register(collapse)

local function spawn_cracking_sound_text(surface, position)
    local text = config.cracking_sounds[math.random(1, #config.cracking_sounds)]

    local color = {
        r = 1,
        g = math.random(1, 100) / 100,
        b = 0
    }

    for i = 1, #text do
        local x_offset = (i - #text / 2 - 1) / 3
        local char = text:sub(i, i)
        surface.create_entity {
                name = 'flying-text',
                color = color,
                text = char,
                position = {x = position.x + x_offset, y = position.y - ((i + 1) % 2) / 4}
            }.active = true
    end
end

local function on_collapse_triggered(event)
      local position = event.position
      local x = position.x
      local y = position.y

      local x_t = new_tile_map[x]
      if x_t and x_t[y] then
          Template.insert(event.surface, {}, {{position = position, name = 'sand-rock-big'}})
      else
          spawn_cracking_sound_text(event.surface, position)
          Task.set_timeout(
              config.collapse_delay,
              on_collapse_timeout_finished,
              {surface = event.surface, position = position}
          )
      end
end

local function on_built_tile(surface, new_tile, tiles)
    local new_tile_strength = support_beam_entities[new_tile.name]

    for _, tile in pairs(tiles) do
        if new_tile_strength then
            stress_map_blur_add(surface, tile.position, -1 * new_tile_strength, 'on_built_tile')
        end

        local old_tile_strength = support_beam_entities[tile.old_tile.name]
        if (old_tile_strength) then
            stress_map_blur_add(surface, tile.position, old_tile_strength, 'on_built_tile')
        end
    end
end

local function on_robot_mined_tile(event)
    for _, tile in pairs(event.tiles) do
        local strength = support_beam_entities[tile.old_tile.name]
        if strength then
            stress_map_blur_add(event.robot.surface, tile.position, strength)
        end
    end
end

local function on_player_mined_tile(event)
    local surface = game.surfaces[event.surface_index]
    for _, tile in pairs(event.tiles) do
        local strength = support_beam_entities[tile.old_tile.name]

        if strength then
            stress_map_blur_add(surface, tile.position, strength)
        end
    end
end

local function on_mined_entity(event)
    local strength = support_beam_entities[event.entity.name]

    if strength then
        stress_map_blur_add(event.entity.surface, event.entity.position, strength)
    end
end

local function on_built_entity(event)
    local strength = support_beam_entities[event.created_entity.name]

    if strength then
        stress_map_blur_add(
            event.created_entity.surface,
            event.created_entity.position,
            -1 * strength,
            'on_built_entity'
        )
    end
end

local function on_placed_entity(event)
    local strength = support_beam_entities[event.entity.name]

    if strength then
        stress_map_blur_add(event.entity.surface, event.entity.position, -1 * strength)
    end
end


local on_new_tile_timeout_finished = Token.register(function(args)
    local x_t = new_tile_map[args.x]
    if x_t then
       x_t[args.y] = nil --reset new tile status. This tile can cause a chain collapse now
    end
end)

local function on_void_removed(event)
    local strength = support_beam_entities['out-of-map']

    local position =  event.old_tile.position
    if strength then
        stress_map_blur_add(event.surface, position, strength)
    end

    local x = position.x
    local y = position.y

    --To avoid room collapse:
    local x_t = new_tile_map[x]
    if x_t then
        x_t[y] = true
    else
        x_t = {
            [y] = true
        }
        new_tile_map[x] = x_t
    end
    Task.set_timeout(3, on_new_tile_timeout_finished, {x = x, y = y})
end

local function on_void_added(event)
    local strength = support_beam_entities['out-of-map']
    if strength then
        stress_map_blur_add(event.surface, event.old_tile.position, -1 * strength)
    end
end

--[[--
    Registers all event handlers.]

    @param global_config Table {@see Diggy.Config}.
]]
function DiggyCaveCollapse.register(cfg)
    config = cfg
    support_beam_entities = config.support_beam_entities

    Event.add(DiggyCaveCollapse.events.on_collapse_triggered, on_collapse_triggered)
    Event.add(defines.events.on_robot_built_entity, on_built_entity)
    Event.add(defines.events.on_robot_built_tile, function (event)
        on_built_tile(event.robot.surface, event.item, event.tiles)
    end)
    Event.add(defines.events.on_player_built_tile, function (event)
        on_built_tile(game.surfaces[event.surface_index], event.item, event.tiles)
    end)
    Event.add(defines.events.on_robot_mined_tile, on_robot_mined_tile)
    Event.add(defines.events.on_player_mined_tile, on_player_mined_tile)
    Event.add(defines.events.on_robot_mined_entity, on_mined_entity)
    Event.add(defines.events.on_built_entity, on_built_entity)
    Event.add(Template.events.on_placed_entity, on_placed_entity)
    Event.add(defines.events.on_entity_died, on_mined_entity)
    Event.add(defines.events.on_player_mined_entity, on_mined_entity)
    Event.add(Template.events.on_void_removed, on_void_removed)
    Event.add(Template.events.on_void_added, on_void_added)
    Event.add(defines.events.on_surface_created, on_surface_created)

    Event.add(defines.events.on_marked_for_deconstruction, function (event)
        if (nil ~= support_beam_entities[event.entity.name]) then
            event.entity.cancel_deconstruction(game.players[event.player_index].force)
        end
    end)

    Event.add(defines.events.on_pre_player_mined_item, function(event)
        if (nil ~= deconstruction_alert_message_shown[event.player_index]) then
            return
        end

        if (nil ~= support_beam_entities[event.entity.name]) then
            require 'popup'.player(
                game.players[event.player_index],
                'Mining entities such as walls, stone paths, concrete and rocks, can cause a cave-in, be careful miner!'
            )
            deconstruction_alert_message_shown[event.player_index] = true
        end
    end)

    enable_stress_grid = config.enable_stress_grid

    on_surface_created({surface_index = 1})

    mask_init(config)
    if (config.enable_mask_debug) then
        local surface = game.surfaces.nauvis
        mask_disc_blur(0, 0, 10,  function(x, y, fraction)
            Debug.print_grid_value(fraction, surface, {x = x, y = y})
        end)
    end
end

--
--STRESS MAP
--
--[[--
    Adds a fraction to a given location on the stress_map. Returns the new
    fraction value of that position.

    @param stress_map Table of {x,y}
    @param position Table with x and y
    @param number fraction

    @return number sum of old fraction + new fraction
]]
local function add_fraction(stress_map, x, y, fraction)
    local quadrant = 1
    if x < 0 then
        quadrant = quadrant + 1
        x = -x
    end
    if y < 0 then
        quadrant = quadrant + 2
        y = -y
    end

    local quad_t = stress_map[quadrant]

    local x_t = quad_t[x]
    if not x_t then
        x_t = {}
        quad_t[x] = x_t
    end

    local value = x_t[y]
    if not value then
        value = defaultValue
    end

    value = value + fraction

    x_t[y] = value

    if (value > stress_threshold_causing_collapse) then
        if quadrant > 2 then
            y = -y
        end
        if quadrant % 2 == 0 then
            x = -x
        end
        script.raise_event(
            DiggyCaveCollapse.events.on_collapse_triggered,
            {surface = game.surfaces[stress_map.surface_index], position = {x = x, y = y}}
        )
    end
    if (enable_stress_grid) then
        local surface = game.surfaces[stress_map.surface_index]
        if quadrant > 2 then
            y = -y
        end
        if quadrant % 2 == 0 then
            x = -x
        end
        Debug.print_grid_value(value, surface, {x = x, y = y})
    end
    return value
end

local function add_fraction_by_quadrant(stress_map, x, y, fraction, quadrant)
    local quad_t = stress_map[quadrant]

    local x_t = quad_t[x]
    if not x_t then
        x_t = {}
        quad_t[x] = x_t
    end

    local value = x_t[y]
    if not value then
        value = defaultValue
    end

    value = value + fraction

    x_t[y] = value

    if (value > stress_threshold_causing_collapse) then
        if quadrant > 2 then
            y = -y
        end
        if quadrant % 2 == 0 then
            x = -x
        end
        script.raise_event(
            DiggyCaveCollapse.events.on_collapse_triggered,
            {surface = game.surfaces[stress_map.surface_index], position = {x = x, y = y}}
        )
    end
    if (enable_stress_grid) then
        local surface = game.surfaces[stress_map.surface_index]
        if quadrant > 2 then
            y = -y
        end
        if quadrant % 2 == 0 then
            x = -x
        end
        Debug.print_grid_value(value, surface, {x = x, y = y})
    end
    return value
end


on_surface_created = function(event)
    stress_map_storage[event.surface_index] = {}

    local map = stress_map_storage[event.surface_index]

    map['surface_index'] = event.surface_index
    map[1] = {}
    map[2] = {}
    map[3] = {}
    map[4] = {}
end

--[[--
    Checks whether a tile's pressure is within a given threshold and calls the handler if not.
    @param surface LuaSurface
    @param position Position with x and y
    @param number threshold
    @param callback

]]
stress_map_check_stress_in_threshold = function(surface, position, threshold, callback)
    local stress_map = stress_map_storage[surface.index]
    local value = add_fraction(stress_map, position.x, position.y, 0)

    if (value >= stress_threshold_causing_collapse - threshold) then
        callback(surface, position)
    end
end

stress_map_blur_add = function(surface, position, factor)
    local x_start = math.floor(position.x)
    local y_start = math.floor(position.y)

    local stress_map = stress_map_storage[surface.index]
    if not stress_map then
        return
    end

    if radius > math.abs(x_start) or radius > math.abs(y_start) then
        for x = -radius, radius do
            for y = -radius, radius do
                local value = 0
                local distance_sq = x * x + y * y
                if distance_sq <= center_radius_sq then
                    value = center_value
                elseif distance_sq <= disc_radius_sq then
                    value = disc_value
                elseif distance_sq <= radius_sq then
                    value = ring_value
                end
                if math.abs(value) > 0.001 then
                    add_fraction(stress_map, x + x_start, y + y_start, value * factor)
                end
            end
        end
    else
        local quadrant = 1
        if x_start < 0 then
            quadrant = quadrant + 1
            x_start = -x_start
        end
        if y_start < 0 then
            quadrant = quadrant + 2
            y_start = -y_start
        end

        for x = -radius, radius do
            for y = -radius, radius do
                local value = 0
                local distance_sq = x * x + y * y
                if distance_sq <= center_radius_sq then
                    value = center_value
                elseif distance_sq <= disc_radius_sq then
                    value = disc_value
                elseif distance_sq <= radius_sq then
                    value = ring_value
                end
                if math.abs(value) > 0.001 then
                    add_fraction_by_quadrant(stress_map, x + x_start, y + y_start, value * factor, quadrant)
                end
            end
        end
    end
end

DiggyCaveCollapse.stress_map_blur_add = stress_map_blur_add

--
-- MASK
--

function mask_init(config)
    n = config.mask_size

    ring_weight = config.mask_relative_ring_weights[1]
    disc_weight = config.mask_relative_ring_weights[2]
    center_weight = config.mask_relative_ring_weights[3]

    radius = math.floor(n / 2)

    radius_sq = (radius + 0.2) * (radius + 0.2)
    center_radius_sq = radius_sq / 9
    disc_radius_sq = radius_sq * 4 / 9

    for x = -radius, radius do
        for y = -radius, radius do
            local distance_sq = x * x + y * y
            if distance_sq <= center_radius_sq then
                disc_blur_sum = disc_blur_sum + center_weight
            elseif distance_sq <= disc_radius_sq then
                disc_blur_sum = disc_blur_sum + disc_weight
            elseif distance_sq <= radius_sq then
                disc_blur_sum = disc_blur_sum + ring_weight
            end
        end
    end
    center_value = center_weight / disc_blur_sum
    disc_value = disc_weight / disc_blur_sum
    ring_value = ring_weight / disc_blur_sum
end

--[[--
    Applies a blur
    Applies the disc in 3 discs: center, (middle) disc and (outer) ring.
    The relative weights for tiles in a disc are:
    center: 3/3
    disc: 2/3
    ring: 1/3
    The sum of all values is 1

    @param x_start number center point
    @param y_start number center point
    @param factor the factor to multiply the cell value with (value = cell_value * factor)
    @param callback function to execute on each tile within the mask callback(x, y, value)
]]
mask_disc_blur = function(x_start, y_start, factor, callback)
    x_start = math.floor(x_start)
    y_start = math.floor(y_start)
    for x = -radius, radius do
        for y = -radius, radius do
            local value = 0
            local distance_sq = x * x + y * y
            if distance_sq <= center_radius_sq then
                value = center_value
            elseif distance_sq <= disc_radius_sq then
                value = disc_value
            elseif distance_sq <= radius_sq then
                value = ring_value
            end
            if math.abs(value) > 0.001 then
                callback(x_start + x, y_start + y, value * factor)
            end
        end
    end
end

function DiggyCaveCollapse.get_extra_map_info(config)
    return [[Alien Spawner, aliens might spawn when mining!
Place stone walls, stone paths and (refined) concrete to reinforce the mine. If you see cracks appear, run!]]
end

return DiggyCaveCollapse
