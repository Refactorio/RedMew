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
local stress_map_add
local mask_disc_blur
local stress_map_check_stress_in_threshold
local support_beam_entities
local on_surface_created

local stress_threshold_causing_collapse = 3.57

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

local function create_collapse_template(positions, surface)
    local entities = {}

    local find_entities_filtered = surface.find_entities_filtered

    for _, position in pairs(positions) do
        local x = position.x
        local y = position.y
        local do_insert = true

        for _, entity in pairs(find_entities_filtered{area = {{x, y}, {x + 1, y + 1}}}) do
            pcall(function()
                local strength = support_beam_entities[entity.name]
                if strength then
                    do_insert = false
                else
                    local position = entity.position
                    entity.die()
                end
            end)
        end
        if do_insert then
            insert(entities, {position = {x = x, y = y}, name = 'sand-rock-big'})
        end
    end
    return entities
end

local function create_collapse_alert(surface, position)
    local target = surface.create_entity{position = position, name = "sand-rock-big"}
    for _,player in pairs(game.connected_players) do
        player.add_custom_alert(target, {type="item", name="stone"}, "Cave collapsed!", true)
    end
    target.destroy()
end

local function collapse(args)
    local position = args.position
    local surface = args.surface
    local positions = {}
    local strength = config.collapse_threshold_total_strength
    create_collapse_alert(surface, position)
    mask_disc_blur(
        position.x,  position.y,
        strength,
        function(x, y, value)
            stress_map_check_stress_in_threshold(
                surface,
                {x = x, y = y},
                value,
                function(_, position)
                    insert(positions, position)
                end
            )
        end
    )
    local entities = create_collapse_template(positions, surface)
    Template.insert(surface, {}, entities)
end

local on_collapse_timeout_finished = Token.register(collapse)

local function spawn_cracking_sound_text(surface, position)
    local text = config.cracking_sounds[random(1, #config.cracking_sounds)]

    local color = {
        r = 1,
        g = random(1, 100) / 100,
        b = 0
    }

    local create_entity = surface.create_entity

    for i = 1, #text do
        local x_offset = (i - #text / 2 - 1) / 3
        local char = text:sub(i, i)
        create_entity {
            name = 'flying-text',
            color = color,
            text = char,
            position = {x = position.x + x_offset, y = position.y - ((i + 1) % 2) / 4}
        }.active = true
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
            stress_map_add(surface, tile.position, -1 * new_tile_strength, true)
        end

        local old_tile_strength = support_beam_entities[tile.old_tile.name]
        if (old_tile_strength) then
            stress_map_add(surface, tile.position, old_tile_strength, true)
        end
    end
end

local function on_robot_mined_tile(event)
    local surface
    for _, tile in pairs(event.tiles) do
        local strength = support_beam_entities[tile.old_tile.name]
        if strength then
            surface = surface or event.robot.surface
            stress_map_add(surface, tile.position, strength, true)
        end
    end
end

local function on_player_mined_tile(event)
    local surface = game.surfaces[event.surface_index]
    for _, tile in pairs(event.tiles) do
        local strength = support_beam_entities[tile.old_tile.name]

        if strength then
            stress_map_add(surface, tile.position, strength, true)
        end
    end
end

local function on_mined_entity(event)
    local entity = event.entity
    local strength = support_beam_entities[entity.name]

    if strength then
        stress_map_add(entity.surface, entity.position, strength)
    end
end

local function on_built_entity(event)
    local entity = event.created_entity
    local strength = support_beam_entities[entity.name]

    if strength then
        stress_map_add(entity.surface, entity.position, -1 * strength)
    end
end

local function on_placed_entity(event)
    local strength = support_beam_entities[event.entity.name]

    if strength then
        stress_map_add(event.entity.surface, event.entity.position, -1 * strength)
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
        stress_map_add(event.surface, position, strength)
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
                game.players[event.player_index],[[
Mining entities such as walls, stone paths, concrete
and rocks, can cause a cave-in, be careful miner!

Foreman's advice: Place a wall every 4th tile to
prevent a cave-in. Use stone paths and concrete
to reinforce it further.
]]
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


    if config.enable_debug_commands then
        commands.add_command('test-tile-support-range', '<tilename> <range> creates a square of tiles with length <range>. It is spawned one <range> north of the player.', function(cmd)
                local params = {}
                for param in string.gmatch(cmd.parameter, '%S+') do
                    table.insert(params, param)
                end

                local tilename = params[1]
                local range = tonumber(params[2])

                local position = {x = math.floor(game.player.position.x), y = math.floor(game.player.position.y) - 5 * range - 1}
                local surface = game.player.surface
                local tiles = {}
                local entities = {}
                for x = position.x, position.x + range * 5 do
                    for y = position.y, position.y + range  * 5 do
                        if y % range + x % range == 0 then
                            insert(entities,{name = "stone-wall", position = {x=x,y=y}})
                        end
                        insert(tiles, {position = {x = x, y = y}, name = tilename})

                        local strength = support_beam_entities[tilename]
                        if strength then
                            stress_map_add(surface, {x =x, y=y}, - strength)
                        end
                        for _, entity in pairs(surface.find_entities_filtered({position = {x=x,y=y}})) do
                            pcall(function()
                                    local strength = support_beam_entities[entity.name]
                                    local position = entity.position
                                    entity.die()
                                    if strength then
                                        stress_map_add(surface, position, strength)
                                    end
                                end
                            )
                        end
                    end
                end
                Template.insert(surface, tiles, entities)
            end
        )
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
local function add_fraction(stress_map, x, y, fraction)
    x = 2 * floor(x / 2)
    y = 2 * floor(y / 2)

    local x_t = stress_map[x]
    if not x_t then
        x_t = {}
        stress_map[x] = x_t
    end

    local value = x_t[y]
    if not value then
        value = defaultValue
    end

    value = value + fraction

    x_t[y] = value

    if (fraction > 0 and value > stress_threshold_causing_collapse) then
        script.raise_event(
            DiggyCaveCollapse.events.on_collapse_triggered,
            {surface = game.surfaces[stress_map.surface_index], position = {x = x, y = y}}
        )
    end
    if (enable_stress_grid) then
        local surface = game.surfaces[stress_map.surface_index]
        Debug.print_grid_value(value, surface, {x = x, y = y}, 4, 0.5)
    end
    return value
end

on_surface_created = function(event)
    stress_map_storage[event.surface_index] = {}

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
    local value = add_fraction(stress_map, position.x, position.y, 0)

    if (value >= stress_threshold_causing_collapse - threshold) then
        callback(surface, position)
    end
end

stress_map_add = function(surface, position, factor, no_blur)
    local x_start = floor(position.x)
    local y_start = floor(position.y)

    local stress_map = stress_map_storage[surface.index]
    if not stress_map then
        return
    end

    if no_blur then
        add_fraction(stress_map, x_start, y_start, factor)
        return
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
            if abs(value) > 0.001 then
                add_fraction(stress_map, x + x_start, y + y_start, value * factor)
            end
        end
    end
end

DiggyCaveCollapse.stress_map_add = stress_map_add

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
