--[[
    Blueprint tools for Diggy

    Support beams (tiles and special entities) cannot be marked for deconstruction by default (antigrief/safety feature).
    Regulars and above will have access to this tool to turn On/Off the safety measure however they prefer.
    The feature will automatically popup whenever the player is about to perform a "blueprint action", which is:
    - using a blueprint record
    - using a blueprint book
    - setting up a blueprint from map
    - holding a blueprintable item-entity in hand

    Players can:
    - turn On/Off the safety measure all together
    - turn On/Off tiles in bulk
    - Show/Hide the popup window (from this window or RedMew "Settings > Show blueprint tools")
    - turn On/Off individual entities
]]

local Command = require 'utils.command'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Rank = require 'features.rank_system'
local Ranks = require 'resources.ranks'
local Settings = require 'utils.redmew_settings'
local Template = require 'map_gen.maps.diggy.template'

local is_diggy_rock = Template.is_diggy_rock
local is_support_beam = Template.is_support_beam
local required_rank = Ranks.regular
local ENTITIES = prototypes.entity
local ITEMS = prototypes.item
local TILES = prototypes.tile

local main_frame_name = Gui.uid_name()
local feature_switch_name = Gui.uid_name()
local entity_button_name = Gui.uid_name()
local tiles_checkbox_name = Gui.uid_name()
local show_window_checkbox_name = Gui.uid_name()

local admin_main_frame_name = Gui.uid_name()
local admin_feature_switch_name = Gui.uid_name()
local admin_entity_button_name = Gui.uid_name()
local admin_close_button_name = Gui.uid_name()

local Public = {
    setting_name = 'diggy_blueprint_tools',
    setting_tooltip = 'diggy.blueprint_tools_tooltip'
}

---@class PlayerSettingsData
---@field enabled boolean
---@field include_tiles boolean
---@field entities table[string --> boolean]

local player_settings = {} --[[@as [player_index] --> PlayerSettingsData]]
Global.register(player_settings, function(tbl) player_settings = tbl end)

local switch_state_map = {
    [true] = 'left',
    [false] = 'right',
    ['left'] = true,
    ['right'] = false,
}

local hidden_entities = {
    ['out-of-map'] = true,
    ['market'] = true,
    ['hazard-concrete'] = true, -- right/left
    ['refined-hazard-concrete'] = true, -- left/right
    ['stone-brick'] = true, -- stone-path
}
do
    -- populate hidden_entities with template rocks
    for _, rock in pairs(Template.diggy_rocks) do
        hidden_entities[rock] = true
    end
end

local cursor_stack_triggers = {
    ['blueprint'] = true,
    ['deconstruction-item'] = true,
}

local is_hidden_entity = function(name)
    return hidden_entities[name] ~= nil
end

local function get_player_settings(player_index)
    local ps = player_settings[player_index]
    if not ps then
        local entities = {}
        for name in pairs(Template.support_beam_entities) do
            if not is_hidden_entity(name) then
                entities[name] = true
            end
        end
        ps = {
            enabled = true,
            include_tiles = true,
            entities = entities,
        }
        player_settings[player_index] = ps
    end
    return ps
end

local function get_sprite_from_name(name)
    if TILES[name] then
        return 'tile.'..name
    elseif ITEMS[name] then
        return 'item.'..name
    elseif ENTITIES[name] then
        return 'entity.'..name
    end
    return 'virtual-signal.signal-deny'
end

local function get_tooltip_from_name(name)
    if TILES[name] then
        return TILES[name].localised_name
    elseif ITEMS[name] then
        return ITEMS[name].localised_name
    elseif ENTITIES[name] then
        return ENTITIES[name].localised_name
    end
    return name
end

local function on_player_cursor_stack_changed(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    -- Regulars+ feature only
    if Rank.less_than(player.name, required_rank) then
        return Public.toggle_main_frame(player, false)
    end

    -- Player has hidden the window
    if not Settings.get(player.index, Public.setting_name) then
        return Public.toggle_main_frame(player, false)
    end

    -- Player has empty cursor
    if player.is_cursor_empty() then
        return Public.toggle_main_frame(player, false)
    end

    -- Player is currently using a blueprint record
    if player.is_cursor_blueprint() then
        return Public.toggle_main_frame(player, true)
    end

    -- Player is holding the ghost of an entity
    -- NOTE: LuaPlayer::cursor_ghost::name returns a LuaItemPrototype when read
    local ghost_prototype = player.cursor_ghost and player.cursor_ghost.name
    if ghost_prototype ~= nil then
        if ENTITIES[ghost_prototype.name] ~= nil then
            return Public.toggle_main_frame(player, true)
        end
    end

    local cursor_stack = player.cursor_stack

    -- Player has invalid cursor
    if not (cursor_stack and cursor_stack.valid_for_read) then
        return Public.toggle_main_frame(player, false)
    end

    -- Player is holding blueprint/decon planner
    if cursor_stack_triggers[cursor_stack.type] then
        return Public.toggle_main_frame(player, true)
    end

    -- Player is holding an entity prototype
    if ENTITIES[cursor_stack.name] ~= nil then
        return Public.toggle_main_frame(player, true)
    end

    Public.toggle_main_frame(player, false)
end

local function on_marked_for_deconstruction(event)
    local entity = event.entity
    local name = entity.name

    if name == 'deconstructible-tile-proxy' then
        name = entity.surface.get_tile(entity.position.x, entity.position.y).name
    end

    -- Rocks are always allowed
    if is_diggy_rock(name) then
        return
    end

    -- Entity is not a support
    if not is_support_beam(name) then
        return
    end

    local player = event.player_index and game.get_player(event.player_index)
    -- NOTE: The only case when a support beam is marked for deconstruction AND there's no player_index
    -- is when player bots-mine rocks and bots have to re-iterate over the rock to fully mine it
    if not player then
        return
    end

    -- Regular+ feature only
    if Rank.less_than(player.name, required_rank) then
        return entity.cancel_deconstruction(player.force)
    end

    local ps = get_player_settings(player.index)
    if not ps.enabled then
        return
    end

    -- Entity is not marked to keep safe
    if not ps.entities[name] then
        return
    end

    entity.cancel_deconstruction(player.force)
end

local function on_setting_set(event)
    if event.setting_name ~= Public.setting_name then
        return
    end

    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    local should_show_gui = Rank.equal_or_greater_than(player.name, required_rank) and event.new_value and event.value_changed
    Public.toggle_main_frame(player, should_show_gui)

    local frame = Gui.get_left_element(player, main_frame_name)
    Gui.get_data(frame).show_window_checkbox.state = should_show_gui
end

local function get_admin_main_frame(_, player)
    local frame = player.gui.screen[admin_main_frame_name]
    if frame and frame.valid then
        Gui.destroy(frame)
    end

    frame = player.gui.screen.add {
        type = 'frame',
        name = admin_main_frame_name,
        direction = 'vertical',
    }
    Gui.set_style(frame, { maximal_height = 930 })

    do -- Header
        local header = frame.add { type = 'flow', direction = 'horizontal' }
        Gui.set_style(header, { horizontal_spacing = 8, vertical_align = 'center', bottom_padding = 4 })

        local label = header.add { type = 'label', caption = 'Blueprint tools management', style = 'frame_title' }
        label.drag_target = frame

        local dragger = header.add { type = 'empty-widget', style = 'draggable_space_header' }
        dragger.drag_target = frame
        Gui.set_style(dragger, { height = 24, horizontally_stretchable = true })

        local button = header.add {
            type = 'sprite-button',
            name = admin_close_button_name,
            sprite = 'utility/close',
            clicked_sprite = 'utility/close_black',
            style = 'close_button',
            tooltip = {'gui.close-instruction'}
        }
        Gui.set_data(button, frame)
    end

    do -- Content
        local inner = frame.add { type = 'frame', style = 'inside_deep_frame', direction = 'vertical' }
        local online = inner
            .add { type = 'frame', style = 'subheader_frame'}
            .add { type = 'label', caption = ('Online: %d/%d'):format(#game.connected_players, #game.players), style = 'subheader_label' }
        Gui.set_style(online.parent, { horizontally_stretchable = true })

        local grid = inner
            .add { type = 'scroll-pane', style = 'naked_scroll_pane' }
            .add { type = 'table', style = 'table_with_selection', column_count = 4 }

        local function make_rank(name)
            local label = grid.add { type = 'label', caption = Rank.get_player_rank_name(name) }
            Gui.set_style(label, { font_color = Rank.get_player_rank_color(name) })
        end

        local function make_switch(index)
            local ps = get_player_settings(index)
            grid.add { type = 'flow' }.add {
                type = 'switch',
                name = admin_feature_switch_name,
                switch_state = switch_state_map[ps.enabled],
                left_label_caption = 'On',
                right_label_caption = 'Off',
                left_label_tooltip = 'Use safe deconstruction mode',
                right_label_tooltip = 'Ignore safe deconstruction mode',
                tags = { index = index },
            }
        end

        local function make_list(index)
            local ps = get_player_settings(index)

            local list = grid
                .add { type = 'scroll-pane', style = 'naked_scroll_pane' }
                .add { type = 'table', column_count = 10, style = 'filter_slot_table' }
            list.parent.horizontal_scroll_policy = 'never'

            for name, status in pairs(ps.entities) do
                list.add{ type = 'flow' }.add{
                    type = 'sprite-button',
                    name = admin_entity_button_name,
                    style = 'slot_button',
                    auto_toggle = true,
                    toggled = status,
                    sprite = get_sprite_from_name(name),
                    tags = { name = name, index = index },
                    tooltip = get_tooltip_from_name(name),
                }
            end
        end

        grid.add { type = 'label', caption = 'Name' }
        grid.add { type = 'label', caption = 'Rank' }
        grid.add { type = 'label', caption = 'Status' }
        grid.add { type = 'label', caption = 'Entities' }

        for index, p in pairs(game.players) do
            grid.add { type = 'label', caption = p.name }
            make_rank(p.name)
            make_switch(index)
            make_list(index)
        end
    end

    frame.force_auto_center()
    player.opened = frame
end

---@param player LuaPlayer
---@return LuaGuiElement
Public.get_main_frame = function(player)
    local frame = Gui.get_left_element(player, main_frame_name)
    if frame and frame.valid then
        return frame
    end

    local data = {}
    local ps = get_player_settings(player.index)
    local should_show_gui = Rank.equal_or_greater_than(player.name, required_rank)

    frame = Gui.add_left_element(player, {
        name = main_frame_name,
        type = 'frame',
        direction = 'vertical',
    })
    Gui.set_style(frame, { maximal_width = 228 })

    frame.add {
        type = 'label',
        style = 'frame_title',
        caption = 'Blueprint tools [img=info]',
        tooltip = 'You can enable/disable this window from \nRedMew Settings > Show blueprint tools'
    }

    local inner = frame
        .add { type = 'frame', style = 'inside_shallow_frame', direction = 'vertical' }
        .add { type = 'flow', direction = 'vertical' }
    Gui.set_style(inner, { padding = 8, vertical_spacing = 4 })

    data.enabled_switch = inner.add {
        type = 'switch',
        name = feature_switch_name,
        caption = 'Feature caption',
        switch_state = switch_state_map[ps.enabled],
        left_label_caption = 'On',
        right_label_caption = 'Off',
        left_label_tooltip = 'Use safe deconstruction mode',
        right_label_tooltip = 'Ignore safe deconstruction mode',
    }
    Gui.set_data(data.enabled_switch, data)

    data.tiles_checkbox = inner.add {
        type = 'checkbox',
        name = tiles_checkbox_name,
        caption = 'Include tiles',
        state = ps.include_tiles,
    }
    Gui.set_data(data.tiles_checkbox, data)

    data.show_window_checkbox = inner.add {
        type = 'checkbox',
        name = show_window_checkbox_name,
        caption = { 'diggy.blueprint_tools_tooltip' },
        state = Settings.get(player.index, Public.setting_name)
    }
    Gui.set_data(data.show_window_checkbox, data)

    inner.add {
        type = 'label',
        style = 'bold_label',
        caption = 'Protected entities:',
        tooltip = 'Selected entities will never be marked for deconstruction'
    }

    data.grid = inner
        .add { type = 'scroll-pane', style = 'deep_slots_scroll_pane' }
        .add { type = 'table', column_count = 5, style = 'filter_slot_table' }

    for name, status in pairs(ps.entities) do
        data.grid.add{ type = 'flow' }.add{
            type = 'sprite-button',
            name = entity_button_name,
            style = 'slot_button',
            auto_toggle = true,
            toggled = status,
            sprite = get_sprite_from_name(name),
            tags = { name = name },
            tooltip = get_tooltip_from_name(name),
            enabled = ps.enabled,
        }
    end

    Gui.set_data(frame, data)
    frame.visible = should_show_gui

    return frame
end

---@param player LuaPlayer
---@param state? boolean
Public.toggle_main_frame = function(player, state)
    local frame = Public.get_main_frame(player, main_frame_name)
    if state == nil then
        state = not frame.visible
    end
    if frame.visible == state then
        return
    end

    frame.visible = state
    if frame.visible then
        -- faster to swap children order rather that redrawing gui on every cursor change event
        local parent = frame.parent
        parent.swap_children(frame.get_index_in_parent(), #parent.children)
    end
end

Public.register = function()
    Settings.register(Public.setting_name, Settings.types.boolean, true, Public.setting_tooltip)
    Event.add(Settings.events.on_setting_set, on_setting_set)

    Event.add(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)
    Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)

    Gui.on_switch_state_changed(feature_switch_name, function(event)
        local state = switch_state_map[event.element.switch_state]
        get_player_settings(event.player_index).enabled = state

        local grid = Gui.get_data(event.element).grid
        for _, child in pairs(grid.children) do
            child.children[1].enabled = state
        end
    end)

    Gui.on_checked_state_changed(tiles_checkbox_name, function(event)
        local state = event.element.state
        local entities = get_player_settings(event.player_index).entities

        for name in pairs(entities) do
            if prototypes.tile[name] then
                entities[name] = state
            end
        end

        local grid = Gui.get_data(event.element).grid
        for _, child in pairs(grid.children) do
            local elem = child.children[1]
            elem.toggled = entities[elem.tags.name]
        end
    end)

    Gui.on_checked_state_changed(show_window_checkbox_name, function(event)
        Settings.set(event.player_index, Public.setting_name, event.element.state)
    end)

    Gui.on_click(entity_button_name, function(event)
        get_player_settings(event.player_index).entities[event.element.tags.name] = event.element.toggled
    end)

    Command.add(
        'blueprint-tools',
        {
            description = { 'command_description.blueprint_tools' },
            required_rank = Ranks.moderator,
            allowed_by_server = false,
        },
        get_admin_main_frame
    )

    Gui.on_click(admin_close_button_name, function(event)
        Gui.destroy(Gui.get_data(event.element))
    end)

    Gui.on_custom_close(admin_main_frame_name, function(event)
        Gui.destroy(event.element)
    end)

    Gui.on_switch_state_changed(admin_feature_switch_name, function(event)
        local state = switch_state_map[event.element.switch_state]
        local player_index = event.element.tags.index
        get_player_settings(player_index).enabled = state

        local target = game.get_player(player_index)
        if not target then
            return
        end
        local frame = Gui.get_left_element(target, main_frame_name)
        if frame then
            Gui.destroy(frame)
        end
    end)

    Gui.on_click(admin_entity_button_name, function(event)
        local player_index = event.element.tags.index
        get_player_settings(player_index).entities[event.element.tags.name] = event.element.toggled

        local target = game.get_player(player_index)
        if not target then
            return
        end
        local frame = Gui.get_left_element(target, main_frame_name)
        if frame then
            Gui.destroy(frame)
        end
    end)
end

return Public
