local Global = require 'utils.global'
local EventFactory = require 'utils.test.event_factory'

local Public = {}

local surface_count = 0

Global.register({surface_count = surface_count}, function(tbl)
    surface_count = tbl.surface_count
end)

local function get_surface_name()
    surface_count = surface_count + 1
    return 'test_surface' .. surface_count
end

local autoplace_settings = {
    tile = {treat_missing_as_default = false, settings = {['grass-1'] = {frequency = 1, size = 1, richness = 1}}}
}

local autoplace_controls = {
    trees = {frequency = 1, richness = 1, size = 0},
    ['enemy-base'] = {frequency = 1, richness = 1, size = 0},
    coal = {frequency = 1, richness = 1, size = 0},
    ['copper-ore'] = {frequency = 1, richness = 1, size = 0},
    ['crude-oil'] = {frequency = 1, richness = 1, size = 0},
    ['iron-ore'] = {frequency = 1, richness = 1, size = 0},
    stone = {frequency = 1, richness = 1, size = 0},
    ['uranium-ore'] = {frequency = 1, richness = 1, size = 0}
}

local cliff_settings = {cliff_elevation_0 = 1024, cliff_elevation_interval = 10, name = 'cliff'}

--- Creates a grass-only scratch surface with its chunks generated, and clears it on the next
-- tick (grass replaces any void a map's own generation left). Doesn't touch any player, so it
-- also works on a headless run (utils/test/headless.lua).
-- @return LuaSurface, and a teardown that deletes it
function Public.create_test_surface(context, options)
    options = options or {}
    local name = options.name or get_surface_name()
    local area = options.area or {64, 64}

    local surface = game.create_surface(name, {
        width = area.x or area[1],
        height = area.y or area[2],
        autoplace_settings = autoplace_settings,
        autoplace_controls = autoplace_controls,
        cliff_settings = cliff_settings
    })

    surface.request_to_generate_chunks({0, 0}, 32)
    surface.force_generate_chunk_requests()

    context:next(function()
        for k, v in pairs(surface.find_entities()) do
            v.destroy()
        end

        surface.destroy_decoratives {area = {{-32, -32}, {32, 32}}}

        -- some maps (Diggy) generate every surface as void
        local void = surface.find_tiles_filtered {area = {{-32, -32}, {32, 32}}, name = 'out-of-map'}
        local ground = {}
        for i = 1, #void do
            ground[i] = {name = 'grass-1', position = void[i].position}
        end
        surface.set_tiles(ground)
    end)

    return surface, function()
        game.delete_surface(surface)
    end
end

--- Creates a scratch surface like create_test_surface and moves the player onto it, with a
-- new character at {0, 0}. The teardown puts the player back.
function Public.startup_test_surface(context, options)
    local player = context.player
    local old_surface = player.surface
    local old_position = player.position
    local old_character = player.character

    local surface, delete_surface = Public.create_test_surface(context, options)
    player.force.chart_all(surface)

    context:next(function()
        player.character = nil
        player.teleport({0, 0}, surface)
        player.create_character()
    end)

    return function()
        player.character = nil
        player.teleport(old_position, old_surface)

        if old_character and old_character.valid then
            player.character = old_character
        end

        delete_surface()
    end
end

function Public.wait_for_chunk_to_be_charted(context, force, surface, chunk_position, next)
    if not force.is_chunk_charted(surface, chunk_position) then
        context:next(function()
            Public.wait_for_chunk_to_be_charted(context, force, surface, chunk_position)
        end)
        return
    end

    if next then
        context:next(next)
    end
end

function Public.modify_lua_object(context, object, key, value)
    if type(object) ~= 'table' then
        error('LuaObjects are userdata since Factorio 2.0 and cannot be modified; use Helper.fake_lua_object and Helper.modify_global instead.', 2)
    end

    local old_value = object[key]
    rawset(object, key, value)

    context:add_teardown(function()
        rawset(object, key, old_value)
    end)
end

-- LuaObjects are userdata since Factorio 2.0, so their fields cannot be
-- replaced. Returns a table that reads and writes through to the given object,
-- except for the overridden fields.
function Public.fake_lua_object(object, overrides)
    return setmetatable(overrides or {}, {
        __index = function(_, key)
            return object[key]
        end,
        __newindex = function(_, key, value)
            object[key] = value
        end
    })
end

-- Replaces a global variable, e.g. the 'game' object, until test teardown.
function Public.modify_global(context, name, value)
    local old_value = _G[name]
    rawset(_G, name, value)

    context:add_teardown(function()
        rawset(_G, name, old_value)
    end)
end

--- Builds a logistic network near `position` for real construction robots: a powered roboport
-- with robots in it, and a storage chest holding `items` ({name, count, quality?} stacks). The
-- game then carries out the ghosts and deconstruction orders a test places within its reach
-- (55 tiles) the way it would for a player's robots, with its own build checks and events, and
-- the robots take back to the chest whatever they are handed or mine. Where a map left void
-- (Diggy), dirt is laid for it first.
-- @return the storage chest, and a teardown that removes the network and its robots
function Public.robot_network(surface, position, items)
    local void = surface.find_tiles_filtered {area = {{position.x - 8, position.y - 8}, {position.x + 8, position.y + 8}}, name = 'out-of-map'}
    local ground = {}
    for i = 1, #void do
        ground[i] = {name = 'dirt-1', position = void[i].position}
    end
    surface.set_tiles(ground)

    local entities = {}
    local function place(name, near)
        local p = surface.find_non_colliding_position(name, near, 32, 1)
        local entity = p and surface.create_entity {name = name, position = p, force = 'player'}
        if not entity then
            error('no room for the test ' .. name .. ' near ' .. near.x .. ',' .. near.y, 3)
        end
        entities[#entities + 1] = entity
        return entity
    end

    local roboport = place('roboport', position)
    local interface = place('electric-energy-interface', roboport.position)
    interface.electric_buffer_size = 1e9
    interface.power_production = 1e7
    place('substation', roboport.position)
    roboport.energy = roboport.electric_buffer_size
    roboport.get_inventory(defines.inventory.roboport_robot).insert {name = 'construction-robot', count = 20}

    local chest = place('storage-chest', roboport.position)
    local inventory = chest.get_inventory(defines.inventory.chest)
    for _, stack in pairs(items or {}) do
        inventory.insert(stack)
    end

    return chest, function()
        local area = {{roboport.position.x - 64, roboport.position.y - 64}, {roboport.position.x + 64, roboport.position.y + 64}}
        for _, robot in pairs(surface.find_entities_filtered {area = area, name = 'construction-robot', force = 'player'}) do
            robot.destroy()
        end
        for _, entity in pairs(entities) do
            if entity.valid then
                entity.destroy()
            end
        end
    end
end

local function get_gui_element_by_name(parent, name)
    if parent.name == name then
        return parent
    end

    for _, child in pairs(parent.children) do
        local found = get_gui_element_by_name(child, name)
        if found then
            return found
        end
    end
end

function Public.get_gui_element_by_name(parent, name)
    if name == nil or name == '' then
        return nil
    end

    return get_gui_element_by_name(parent, name)
end

function Public.click(element)
    local element_type = element.type

    if element_type == 'checkbox' then
        element.state = not element.state
        local state_event = EventFactory.on_gui_checked_state_changed(element)
        EventFactory.raise(state_event)
    elseif element_type == 'radiobutton' and not element.state then
        element.state = true
        local state_event = EventFactory.on_gui_checked_state_changed(element)
        EventFactory.raise(state_event)
    end

    local click_event = EventFactory.on_gui_click(element)
    EventFactory.raise(click_event)
end

function Public.set_checkbox(element, state)
    if element.type ~= 'checkbox' then
        error('element is not a checkbox', 2)
    end

    local old_state = not not element.state
    if old_state == state then
        return
    end

    element.state = state
    local state_event = EventFactory.on_gui_checked_state_changed(element)
    EventFactory.raise(state_event)

    local click_event = EventFactory.on_gui_click(element)
    EventFactory.raise(click_event)
end

function Public.set_text(element, text)
    if element.text == text then
        return
    end

    element.text = text
    local text_event = EventFactory.on_gui_text_changed(element, text)
    EventFactory.raise(text_event)
end

return Public
