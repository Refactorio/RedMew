local Event = require 'utils.event'
local Global = require 'utils.global'
local Game = require 'utils.game'
local RS = require 'map_gen.shared.redmew_surface'

local chart_tags = {}

Global.register(
    {
        chart_tags = chart_tags
    },
    function(tbl)
        chart_tags = tbl.chart_tags
    end
)

local function console_chat(event)
    if not event.player_index or event.player_index == nil then
        return
    end
    local player = Game.get_player_by_index(event.player_index)
    local player_force = player.force
    for _, force in pairs(game.forces) do
        if (string.find(force.name, 'quadrant')) ~= nil or force.name == 'player' then
            if force.name ~= player_force.name then
                if player.tag ~= nil or player.tag ~= '' then
                    force.print(player.name .. ' ' .. player.tag .. ': ' .. event.message, player.chat_color)
                else
                    force.print(player.name .. ': ' .. event.message, player.chat_color)
                end
            end
        end
    end
end

--[[local function create_tag(creating_force, data, remove)
    local surface = RS.get_surface()
    local tags
    for _, force in pairs(game.forces) do
        if (string.find(force.name, 'quadrant')) ~= nil then
            if force.name ~= creating_force.name then
                local old_tag =
                    force.find_chart_tags(
                    surface,
                    {{data.position.x - 0.5, data.position.y - 0.5}, {data.position.x + 0.5, data.position.y + 0.5}}
                )[1]
                if old_tag and old_tag.valid then
                    if remove then
                        old_tag.destroy()
                    else
                        old_tag.icon = data.icon
                        old_tag.last_user = data.last_user
                        old_tag.text = data.text
                    end
                else
                    force.add_chart_tag(surface, data)
                end
            end
        end
    end
    return tags
end

local function chart_tag_event(event, remove)
    local tag = event.tag
    local force = event.force
    local modify = false
    if remove ~= nil and not remove then
        modify = true
    end
    remove = remove ~= nil and remove or false
    if string.find(force.name, 'quadrant') == nil then
        return
    end
    if chart_tags.position ~= nil and not modify then
        if chart_tags.position.x == tag.position.x and chart_tags.position.y == tag.position.y then
            return
        end
    elseif modify and chart_tags.text == tag.text and chart_tags.icon == tag.icon then
        return
    end
    chart_tags = {icon = tag.icon, position = tag.position, text = tag.text, last_user = tag.last_user}
    create_tag(force, chart_tags, remove)
end

local function chart_tag_modified(event)
    chart_tag_event(event, false)
end

local function chart_tag_remove(event)
    chart_tags = {}
    chart_tag_event(event, true)
end

Event.add(defines.events.on_chart_tag_added, chart_tag_event)
Event.add(defines.events.on_chart_tag_modified, chart_tag_modified)
Event.add(defines.events.on_chart_tag_removed, chart_tag_remove)]]

Event.add(defines.events.on_console_chat, console_chat)
