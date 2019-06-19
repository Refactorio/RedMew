local Event = require 'utils.event'
local Global = require 'utils.global'
local Settings = require 'utils.redmew_settings'
local pairs = pairs
local settings_get = Settings.get
local settings_set = Settings.set
local settings_validate = Settings.validate

local enable_autofill_name = 'autofill.enabled'
local ammo_count_name = 'autofill.ammo_count'

Settings.register(enable_autofill_name, Settings.types.boolean, true, 'autofill.enable')
Settings.register(ammo_count_name, Settings.types.positive_integer, 10, 'autofill.ammo_count')

local Public = {}

local ammo_locales = {
    ['uranium-rounds-magazine'] = {'item-name.uranium-rounds-magazine'},
    ['piercing-rounds-magazine'] = {'item-name.piercing-rounds-magazine'},
    ['firearm-magazine'] = {'item-name.firearm-magazine'}
}
Public.ammo_locales = ammo_locales

local player_ammos = {} -- player_index -> dict of name -> bool

Global.register(
    player_ammos,
    function(tbl)
        player_ammos = tbl
    end
)

local default_ammos = {
    ['uranium-rounds-magazine'] = true,
    ['piercing-rounds-magazine'] = true,
    ['firearm-magazine'] = true
}

local function copy(tbl)
    local result = {}

    for k, v in pairs(tbl) do
        result[k] = v
    end

    return result
end

function Public.get_player_ammos(player_index)
    return player_ammos[player_index] or default_ammos
end
local get_player_ammos = Public.get_player_ammos

function Public.set_player_ammo(player_index, name, value)
    local pa = player_ammos[player_index] or copy(default_ammos)

    pa[name] = value

    player_ammos[player_index] = pa
end

local function entity_built(event)
    local entity = event.created_entity

    if not entity.valid then
        return
    end

    if entity.type ~= 'ammo-turret' then
        return
    end

    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player or not player.valid then
        return
    end

    local enabled = settings_get(player_index, enable_autofill_name)
    if not enabled then
        return
    end

    local inventory = player.get_main_inventory()
    if not inventory or not inventory.valid then
        return
    end

    local stack = {name = nil, count = settings_get(player_index, ammo_count_name)}

    for name, ammo_enabled in pairs(get_player_ammos(player_index)) do
        if not ammo_enabled then
            goto continue
        end

        stack.name = name
        local removed = inventory.remove(stack)

        if removed > 0 then
            stack.count = removed

            local inserted = entity.insert(stack)
            local diff = removed - inserted
            if diff > 0 then
                stack.count = diff
                inventory.insert(stack)
            end

            local remaining_count = inventory.get_item_count(name)

            player.surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = {'autofill.insert_item', inserted, ammo_locales[name], remaining_count}
                }
            )

            break
        end

        ::continue::
    end
end

Event.add(defines.events.on_built_entity, entity_built)

function Public.get_enabled(player_index)
    return settings_get(player_index, enable_autofill_name)
end

function Public.set_enabled(player_index, value)
    settings_set(player_index, enable_autofill_name, value)
end

function Public.get_ammo_count(player_index)
    return settings_get(player_index, ammo_count_name)
end

function Public.set_ammo_count(player_index, value)
    if settings_validate(ammo_count_name, value) == nil then
        settings_set(player_index, ammo_count_name, value)
        return true
    else
        return false
    end
end

Public.enable_autofill_name = enable_autofill_name
Public.ammo_count_name = ammo_count_name

return Public
