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
local Global = require 'utils.global'
local insert = table.insert
local random = math.random
local floor = math.floor
local abs = math.abs

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
local stress_map_blur_add
local mask_disc_blur
local stress_map_check_stress_in_threshold
local support_beam_entities
local on_surface_created

local stress_threshold_causing_collapse = 0.9

local deconstruction_alert_message_shown = {}
local stress_map_storage = {}
local new_tile_map = {}
local collapse_positions_storage = {}
local cave_collapse_disabled = nil


Global.register({
    new_tile_map = new_tile_map,
    stress_map_storage = stress_map_storage,
    deconstruction_alert_message_shown = deconstruction_alert_message_shown,
    collapse_positions_storage = collapse_positions_storage,
    cave_collapse_disabled = cave_collapse_disabled,
}, function(tbl)
    new_tile_map = tbl.new_tile_map
    stress_map_storage = tbl.stress_map_storage
    deconstruction_alert_message_shown = tbl.deconstruction_alert_message_shown
    collapse_positions_storage = tbl.collapse_positions_storage
    cave_collapse_disabled = tbl.cave_collapse_disabled
end)

local defaultValue = 0

DiggyCaveCollapse.events = {
    --[[--
        When stress at certain position is above the collapse threshold
         - position LuaPosition
         - surface LuaSurface
    ]]
    on_collapse_triggered = script.generate_event_name()
}

local function create_collapse_template(map, surface)
    local entities = {}
    local tiles = {}
    for x,y_tbl in pairs(map) do
        for y,_ in pairs(y_tbl) do
            insert(tiles, {position = {x = x, y = y}, name = 'out-of-map'})
            if not map[x] or not map[x][y - 1] then
                insert(entities, {position = {x = x, y = y - 1}, name = 'sand-rock-big'})
            end
            if not map[x] or not map[x][y + 1] then
                insert(entities, {position = {x = x, y = y + 1}, name = 'sand-rock-big'})
            end
            if not map[x - 1] or not map[x - 1][y] then
                insert(entities, {position = {x = x - 1, y = y}, name = 'sand-rock-big'})
            end
            if not map[x + 1] or not map[x + 1][y] then
                insert(entities, {position = {x = x + 1, y = y}, name = 'sand-rock-big'})
            end
        end
    end

    local find_entities_filtered = surface.find_entities_filtered

    for _, new_spawn in pairs({entities, tiles}) do
        for _, tile in pairs(new_spawn) do
            for _, entity in pairs(find_entities_filtered({position = tile.position})) do
                pcall(function()
                    local strength = support_beam_entities[entity.name]
                    entity.die()
                    if strength then
                        local position = entity.position
                        stress_map_blur_add(surface, position, strength)
                    end
                end)
            end
        end
    end

    return tiles, entities
end

local function spawn_cracking_sound_text(surface, position)
    local text = config.cracking_sounds[random(1, #config.cracking_sounds)]

    local color = {
        r = 1,
        g = random(1, 100) / 100,
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

local function schedule_collapse(args)
    local surface = args.surface
    local surface_index = surface.index
    local collapse_positions_map = collapse_positions_storage[surface_index]
    local position = args.position

    mask_disc_blur(
        position.x,  position.y,
        config.collapse_threshold_total_strength,
        function(x, y, value) --optimize this!
            stress_map_check_stress_in_threshold(
                surface,
                {x = x, y = y},
                value,
                function(_, position)
                    local x = position.x
                    local y = position.y
                    if collapse_positions_map[x] then
                        collapse_positions_map[x][y] = true
                    else
                        collapse_positions_map[x] = {[y] = true}
                    end
                end
            )
        end
    )
end

local on_collapse_timeout_finished = Token.register(schedule_collapse)

local function execute_collapses()
    for surface_index, map in pairs(collapse_positions_storage) do
        local surface = game.surfaces[surface_index]
        local tiles, entities = create_collapse_template(map, surface)
        collapse_positions_storage[surface_index] = {}
        Template.insert(surface, tiles, entities)
    end
end

local function on_collapse_triggered(event)

    if cave_collapse_disabled then return end --kill switch

    local surface = event.surface
    local position = event.position
    local x = position.x
    local y = position.y

    local x_t = new_tile_map[x]
    if x_t and x_t[y] then
        Template.insert(surface, {}, {{position = position, name = 'sand-rock-big'}})
        return
    end
    spawn_cracking_sound_text(surface, position)
    Task.set_timeout(
        config.collapse_delay,
        on_collapse_timeout_finished,
        {surface = surface, position = position}
    )
end

local function on_built_tile(surface, new_tile, tiles)
    local new_tile_strength = support_beam_entities[new_tile.name]

    for _, tile in pairs(tiles) do
        if new_tile_strength then
            stress_map_blur_add(surface, tile.position, -1 * new_tile_strength)
        end

        local old_tile_strength = support_beam_entities[tile.old_tile.name]
        if (old_tile_strength) then
            stress_map_blur_add(surface, tile.position, old_tile_strength)
        end
    end
end

local function on_robot_mined_tile(event)
    local surface
    for _, tile in pairs(event.tiles) do
        local strength = support_beam_entities[tile.old_tile.name]
        if strength then
            surface = surface or event.robot.surface
            stress_map_blur_add(surface, tile.position, strength)
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
    local entity = event.entity
    local strength = support_beam_entities[entity.name]

    if strength then
        stress_map_blur_add(entity.surface, entity.position, strength)
    end
end

local function on_built_entity(event)
    local entity = event.created_entity
    local strength = support_beam_entities[entity.name]

    if strength then
        stress_map_blur_add(entity.surface, entity.position, -1 * strength)
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

    Event.on_nth_tick(80, execute_collapses)

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
                'Mining entities such as walls, stone paths, concrete \nand rocks, can cause a cave-in, be careful miner!'
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

    commands.add_command('toggle-cave-collapse', 'Toggles cave collapse (admins only).', function()
      pcall(function() --better safe than sorry
          if not game.player or game.player.admin then
              cave_collapse_disabled = not cave_collapse_disabled
              if cave_collapse_disabled then
                  game.print("Cave collapse: Disabled.")
              else
                  game.print("Cave collapse: Enabled.")
              end
          end
      end)
    end)
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
local function add_fraction(stress_map, x, y, fraction, no_collapse)
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

    if (value > stress_threshold_causing_collapse and fraction > 0) then
        if quadrant > 2 then
            y = -y
        end
        if quadrant % 2 == 0 then
            x = -x
        end
        if not no_collapse then
            script.raise_event(
                DiggyCaveCollapse.events.on_collapse_triggered,
                {surface = game.surfaces[stress_map.surface_index], position = {x = x, y = y}}
            )
        end
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
    local x_t = quadrant[x]
    if not x_t then
        x_t = {}
        quadrant[x] = x_t
    end

    local value = x_t[y]
    if not value then
        value = defaultValue
    end

    value = value + fraction

    x_t[y] = value

    if (value > stress_threshold_causing_collapse and fraction > 0) then
        local index = quadrant.index
        if index > 2 then
            y = -y
        end
        if index % 2 == 0 then
            x = -x
        end
        script.raise_event(
            DiggyCaveCollapse.events.on_collapse_triggered,
            {surface = game.surfaces[stress_map.surface_index], position = {x = x, y = y}}
        )
    end
    if (enable_stress_grid) then
        local surface = game.surfaces[stress_map.surface_index]
        local index = quadrant.index
        if index > 2 then
            y = -y
        end
        if index % 2 == 0 then
            x = -x
        end
        Debug.print_grid_value(value, surface, {x = x, y = y})
    end
    return value
end


on_surface_created = function(event)
    stress_map_storage[event.surface_index] = {}

    collapse_positions_storage[event.surface_index] = {}

    local map = stress_map_storage[event.surface_index]

    map['surface_index'] = event.surface_index
    map[1] = {index = 1}
    map[2] = {index = 2}
    map[3] = {index = 3}
    map[4] = {index = 4}
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
    local value = add_fraction(stress_map, position.x, position.y, 0, true)

    if (value >= stress_threshold_causing_collapse - threshold) then
        callback(surface, position)
    end
end

stress_map_blur_add = function(surface, position, factor)

    local x_start = floor(position.x)
    local y_start = floor(position.y)

    local stress_map = stress_map_storage[surface.index]
    if not stress_map then
        return
    end

    if radius > abs(x_start) or radius > abs(y_start) then
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
                if abs(value) > 0.001 then
                    add_fraction(stress_map, x + x_start, y + y_start, value * factor)
                end
            end
        end
    else
        local quadrant_n = 1
        if x_start < 0 then
            quadrant_n = quadrant_n + 1
            x_start = -x_start
        end
        if y_start < 0 then
            quadrant_n = quadrant_n + 2
            y_start = -y_start
        end
        local quadrant = stress_map[quadrant_n]
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
                if abs(value) > 0.001 then
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

    radius = floor(n / 2)

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
    x_start = floor(x_start)
    y_start = floor(y_start)
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
            if abs(value) > 0.001 then
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
