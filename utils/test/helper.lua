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

function Public.startup_test_surface(context, options)
    options = options or {}
    local name = options.name or get_surface_name()
    local area = options.area or {64, 64}

    local player = context.player
    local old_surface = player.surface
    local old_position = player.position
    local old_character = player.character

    local surface = game.create_surface(name, {
        width = area.x or area[1],
        height = area.y or area[2],
        autoplace_settings = autoplace_settings,
        autoplace_controls = autoplace_controls,
        cliff_settings = cliff_settings
    })

    surface.request_to_generate_chunks({0, 0}, 32)
    surface.force_generate_chunk_requests()
    player.force.chart_all(surface)

    context:next(function()
        for k, v in pairs(surface.find_entities()) do
            v.destroy()
        end

        surface.destroy_decoratives {area = {{-32, -32}, {32, 32}}}

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

        game.delete_surface(surface)
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
    local old_value = object[key]
    rawset(object, key, value)

    context:add_teardown(function()
        rawset(object, key, old_value)
    end)
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
