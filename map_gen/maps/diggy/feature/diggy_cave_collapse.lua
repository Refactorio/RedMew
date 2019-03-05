--[[-- info
    Provides the ability to collapse caves when digging.
]]
-- dependencies
local Event = require 'utils.event'
local Template = require 'map_gen.maps.diggy.template'
local ScoreTable = require 'map_gen.maps.diggy.score_table'
local Debug = require 'map_gen.maps.diggy.debug'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Game = require 'utils.game'
local CreateParticles = require 'features.create_particles'
local RS = require 'map_gen.shared.redmew_surface'
local table = require 'utils.table'

local random = math.random
local floor = math.floor
local pairs = pairs
local pcall = pcall
local is_diggy_rock = Template.is_diggy_rock
local increment_score = ScoreTable.increment
local template_insert = Template.insert
local raise_event = script.raise_event
local set_timeout = Task.set_timeout
local set_timeout_in_ticks = Task.set_timeout_in_ticks
local ceiling_crumble = CreateParticles.ceiling_crumble
local clear_table = table.clear_table
local collapse_rocks = Template.diggy_rocks
local collapse_rocks_size = #collapse_rocks

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
local mask_init
local stress_map_check_stress_in_threshold
local support_beam_entities
local on_surface_created

local stress_threshold_causing_collapse = 3.57
local near_stress_threshold_causing_collapse = 3.3 -- just above the threshold of a normal 4 pillar grid

local show_deconstruction_alert_message = {}
local stress_map_storage = {}
local new_tile_map = {}
local collapse_positions_storage = {}

Global.register(
    {
        new_tile_map = new_tile_map,
        stress_map_storage = stress_map_storage,
        deconstruction_alert_message_shown = show_deconstruction_alert_message,
        collapse_positions_storage = collapse_positions_storage
    },
    function(tbl)
        new_tile_map = tbl.new_tile_map
        stress_map_storage = tbl.stress_map_storage
        show_deconstruction_alert_message = tbl.deconstruction_alert_message_shown
        collapse_positions_storage = tbl.collapse_positions_storage
    end
)

local defaultValue = 0
local collapse_alert = {type = 'item', name = 'stone'}

DiggyCaveCollapse.events = {
    --[[--
        When stress at certain position is above the collapse threshold
         - position LuaPosition
         - surface LuaSurface
         - player_index Number (index of player that caused the collapse)
    ]]
    on_collapse_triggered = Event.generate_event_name('on_collapse_triggered'),
    --[[--
        After a collapse
         - position LuaPosition
         - surface LuaSurface
         - player_index Number (index of player that caused the collapse)
    ]]
    on_collapse = Event.generate_event_name('on_collapse')
}

local function create_collapse_template(positions, surface)
    local entities = {}
    local entity_count = 0
    local find_entities_filtered = surface.find_entities_filtered

    for _, position in pairs(positions) do
        local x = position.x
        local y = position.y
        local do_insert = true

        for _, entity in pairs(find_entities_filtered({area = {position, {x + 1, y + 1}}})) do
            pcall(
                function()
                    local strength = support_beam_entities[entity.name]
                    if strength then
                        do_insert = false
                    else
                        entity.die()
                    end
                end
            )
        end

        if do_insert then
            entity_count = entity_count + 1
            entities[entity_count] = {position = position, name = collapse_rocks[random(collapse_rocks_size)]}
        end
    end

    return entities
end

local function create_collapse_alert(surface, position)
    local target = surface.create_entity({position = position, name = 'rock-big'})
    for _, player in pairs(game.connected_players) do
        player.add_custom_alert(target, collapse_alert, 'Cave collapsed!', true)
    end
    target.destroy()
end

local function collapse(args)
    local position = args.position
    local surface = args.surface
    local positions = {}
    local count = 0
    local strength = config.collapse_threshold_total_strength
    mask_disc_blur(
        position.x,
        position.y,
        strength,
        function(x, y, value)
            stress_map_check_stress_in_threshold(
                surface,
                x,
                y,
                value,
                function(_, c_x, c_y)
                    count = count + 1
                    positions[count] = {x = c_x, y = c_y}
                end
            )
        end
    )

    if #positions == 0 then
        return
    end

    create_collapse_alert(surface, position)

    template_insert(surface, {}, create_collapse_template(positions, surface))

    raise_event(DiggyCaveCollapse.events.on_collapse, args)
    increment_score('Cave collapse')
end

local on_collapse_timeout_finished = Token.register(collapse)
local on_near_threshold =
    Token.register(
    function(params)
        ceiling_crumble(params.surface, params.position)
    end
)

local function spawn_collapse_text(surface, position)
    local color = {
        r = 1,
        g = random(1, 100) * 0.01,
        b = 0
    }

    surface.create_entity({
        name = 'tutorial-flying-text',
        color = color,
        text = config.cracking_sounds[random(#config.cracking_sounds)],
        position = position,
    })
end

local function on_collapse_triggered(event)
    local surface = event.surface
    local position = event.position
    local x = position.x
    local y = position.y

    local x_t = new_tile_map[x]
    if x_t and x_t[y] then
        template_insert(surface, {}, {{position = position, name = 'rock-big'}})
        return
    end
    spawn_collapse_text(surface, position)
    set_timeout(config.collapse_delay, on_collapse_timeout_finished, event)
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

--It is impossible to track which player marked the tile for deconstruction
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
            stress_map_add(surface, tile.position, strength, true, event.player_index)
        end
    end
end

local function on_mined_entity(event)
    local entity = event.entity
    local name = entity.name
    local strength = support_beam_entities[name]
    if strength then
        local player_index
        if not is_diggy_rock(name) then
            player_index = event.player_index
        end
        stress_map_add(entity.surface, entity.position, strength, false, player_index)
    end
end

local function on_entity_died(event)
    local entity = event.entity
    local name = entity.name
    local strength = support_beam_entities[name]
    if strength then
        local player_index
        if not is_diggy_rock(name) then
            local cause = event.cause
            player_index = cause and cause.type == 'player' and cause.player and cause.player.index or nil
        end
        stress_map_add(entity.surface, entity.position, strength, false, player_index)
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

local on_new_tile_timeout_finished =
    Token.register(
    function(args)
        local x_t = new_tile_map[args.x]
        if x_t then
            x_t[args.y] = nil --reset new tile status. This tile can cause a chain collapse now
        end
    end
)

local function on_void_removed(event)
    local strength = support_beam_entities['out-of-map']

    local position = event.position
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
    set_timeout(3, on_new_tile_timeout_finished, {x = x, y = y})
end

--[[--
    Registers all event handlers.]

    @param global_config Table {@see Diggy.Config}.
]]
function DiggyCaveCollapse.register(cfg)
    config = cfg
    support_beam_entities = config.support_beam_entities

    if support_beam_entities['stone-path'] then
        support_beam_entities['stone-brick'] = support_beam_entities['stone-path']
    else
        support_beam_entities['stone-brick'] = nil
    end

    if support_beam_entities['hazard-concrete'] then
        support_beam_entities['hazard-concrete-left'] = support_beam_entities['hazard-concrete']
        support_beam_entities['hazard-concrete-right'] = support_beam_entities['hazard-concrete']
    else
        support_beam_entities['hazard-concrete-left'] = nil
        support_beam_entities['hazard-concrete-right'] = nil
    end

    if support_beam_entities['refined-hazard-concrete'] then
        support_beam_entities['refined-hazard-concrete-left'] = support_beam_entities['refined-hazard-concrete']
        support_beam_entities['refined-hazard-concrete-right'] = support_beam_entities['refined-hazard-concrete']
    else
        support_beam_entities['refined-hazard-concrete-left'] = nil
        support_beam_entities['refined-hazard-concrete-right'] = nil
    end

    ScoreTable.reset('Cave collapse')

    Event.add(DiggyCaveCollapse.events.on_collapse_triggered, on_collapse_triggered)
    Event.add(defines.events.on_robot_built_entity, on_built_entity)
    Event.add(
        defines.events.on_robot_built_tile,
        function(event)
            on_built_tile(event.robot.surface, event.item, event.tiles)
        end
    )
    Event.add(
        defines.events.on_player_built_tile,
        function(event)
            on_built_tile(game.surfaces[event.surface_index], event.item, event.tiles)
        end
    )
    Event.add(defines.events.on_robot_mined_tile, on_robot_mined_tile)
    Event.add(defines.events.on_player_mined_tile, on_player_mined_tile)
    Event.add(defines.events.on_built_entity, on_built_entity)
    Event.add(Template.events.on_placed_entity, on_placed_entity)
    Event.add(defines.events.on_entity_died, on_entity_died)
    Event.add(defines.events.on_player_mined_entity, on_mined_entity)
    Event.add(Template.events.on_void_removed, on_void_removed)
    Event.add(defines.events.on_surface_created, on_surface_created)

    Event.add(
        defines.events.on_marked_for_deconstruction,
        function(event)
            local entity = event.entity
            local name = entity.name
            if is_diggy_rock(name) then
                return
            end

            if name == 'deconstructible-tile-proxy' or nil ~= support_beam_entities[name] then
                entity.cancel_deconstruction(Game.get_player_by_index(event.player_index).force)
            end
        end
    )

    Event.add(
        defines.events.on_player_created,
        function(event)
            show_deconstruction_alert_message[event.player_index] = true
        end
    )

    Event.add(
        defines.events.on_pre_player_mined_item,
        function(event)
            local player_index = event.player_index
            if not show_deconstruction_alert_message[player_index] then
                return
            end

            if (nil ~= support_beam_entities[event.entity.name]) then
                require 'features.gui.popup'.player(
                    Game.get_player_by_index(player_index),
                    [[
Mining entities such as walls, stone paths, concrete
and rocks, can cause a cave-in, be careful miner!

Foreman's advice: Place a wall every 4th tile to
prevent a cave-in. Use stone paths and concrete
to reinforce it further.
]]
                )
                show_deconstruction_alert_message[player_index] = nil
            end
        end
    )

    enable_stress_grid = config.enable_stress_grid

    on_surface_created({surface_index = 1})

    mask_init(config)
    if (config.enable_mask_debug) then
        local surface = RS.get_surface()
        mask_disc_blur(
            0,
            0,
            10,
            function(x, y, fraction)
                Debug.print_grid_value(fraction, surface, {x = x, y = y})
            end
        )
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
---Adds a fraction to a given location on the stress_map. Returns the new fraction value of that position.
---@param stress_map table
---@param x number
---@param y number
---@param fraction number
---@param player_index number
---@param surface LuaSurface
local function add_fraction(stress_map, x, y, fraction, player_index, surface)
    x = 2 * floor(x * 0.5)
    y = 2 * floor(y * 0.5)

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

    if fraction > 0 then
        if value > stress_threshold_causing_collapse then
            raise_event(
                DiggyCaveCollapse.events.on_collapse_triggered,
                {
                    surface = surface,
                    position = {x = x, y = y},
                    player_index = player_index
                }
            )
        elseif value > near_stress_threshold_causing_collapse then
            set_timeout_in_ticks(2, on_near_threshold, {surface = surface, position = {x = x, y = y}})
        end
    end
    if enable_stress_grid then
        Debug.print_colored_grid_value(value, surface, {x = x, y = y}, 0.5, false, value / stress_threshold_causing_collapse, {r = 0, g = 1, b = 0}, {r = 1, g = -1, b = 0}, {r = 0, g = 1, b = 0}, {r = 1, g = 1, b = 1})
    end
    return value
end

on_surface_created = function(event)
    local index = event.surface_index

    if stress_map_storage[index] then
        clear_table(stress_map_storage[index])
    else
        stress_map_storage[index] = {}
    end

    local map = stress_map_storage[index]

    map['surface_index'] = index
    map[1] = {index = 1}
    map[2] = {index = 2}
    map[3] = {index = 3}
    map[4] = {index = 4}
end

---Checks whether a tile's pressure is within a given threshold and calls the handler if not.
---@param surface LuaSurface
---@param x number
---@param y number
---@param threshold number
---@param callback function
stress_map_check_stress_in_threshold = function(surface, x, y, threshold, callback)
    local stress_map = stress_map_storage[surface.index]
    local value = add_fraction(stress_map, x, y, 0, nil, surface)

    if (value >= stress_threshold_causing_collapse - threshold) then
        callback(surface, x, y)
    end
end

stress_map_add = function(surface, position, factor, no_blur, player_index)
    local x_start = floor(position.x)
    local y_start = floor(position.y)

    local stress_map = stress_map_storage[surface.index]
    if not stress_map then
        return
    end

    if no_blur then
        add_fraction(stress_map, x_start, y_start, factor, player_index, surface)
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
            if value > 0.001 or value < -0.001 then
                add_fraction(stress_map, x + x_start, y + y_start, value * factor, player_index, surface)
            end
        end
    end
end

DiggyCaveCollapse.stress_map_add = stress_map_add

--
-- MASK
--

mask_init = function(config) -- luacheck: ignore 431 (intentional upvalue shadow)
    n = config.mask_size
    local ring_weights = config.mask_relative_ring_weights

    ring_weight = ring_weights[1]
    disc_weight = ring_weights[2]
    center_weight = ring_weights[3]

    radius = floor(n * 0.5)

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
            if value > 0.001 or value < -0.001 then
                callback(x_start + x, y_start + y, value * factor)
            end
        end
    end
end

function DiggyCaveCollapse.get_extra_map_info()
    return [[Cave Collapse, it might just collapse!
Place stone walls, stone paths and (refined) concrete to reinforce the mine. If you see cracks appear, run!]]
end

Event.on_init(
    function()
        if global.config.redmew_surface.enabled then
            on_surface_created({surface_index = RS.get_surface().index})
        end
    end
)

return DiggyCaveCollapse
