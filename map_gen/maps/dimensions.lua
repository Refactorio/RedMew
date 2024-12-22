--Author: Valansch

local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local wrech_items_module = require 'map_gen.shared.wreck_items'

local resource_types = {'copper-ore', 'iron-ore', 'coal', 'stone', 'uranium-ore', 'crude-oil'}

local Public = {}

storage.current_portal_index = 1
storage.portals = {}
--Sample Portal:
--{position : LuaPosition, source: LuaSurface, target : LuaPosition, target_surface : LuaSurface}

storage.current_magic_chest_index = 1
storage.magic_chests = {}
--{entity : LuaEntity, target : LuaEntity}

storage.last_tp = {}
storage.teleport_cooldown = 3
storage.portal_radius = 2

local function get_nice_surface_name(name)
    name = name:gsub('-ore', ''):gsub('-oil', ' Oil')
    return name:sub(1, 1):upper() .. name:sub(2)
end

--Creates autoplace_controls with only one resource type enabled
local function create_resource_setting(resource)
    local settings = RS.get_surface().map_gen_settings
    for _, type in pairs(resource_types) do
        settings.autoplace_controls[type] = {frequency = 'none', size = 'none', richness = 'none'}
    end
    settings.autoplace_controls[resource] = {frequency = 'normal', size = 'big', richness = 'good'}
    return settings
end

local function init()
    local rs_index = RS.get_surface().index + 1
    if not game.surfaces[rs_index] then
        for _, type in pairs(resource_types) do
            game.create_surface(get_nice_surface_name(type), create_resource_setting(type))
        end
        local enemy_settings = create_resource_setting('enemy-base')
        enemy_settings.autoplace_controls['enemy-base'] = {frequency = 'very-high', size = 'very-big', richness = 'very-good'}
        game.create_surface('Zerus', enemy_settings)
        game.create_surface('Nihil', create_resource_setting('copper-ore'))
    end
end

local function generate_nihil(event)
    for _, e in pairs(event.surface.find_entities_filtered {}) do
        if e.type ~= 'character' then
            e.destroy()
        end
    end
    local tiles = {}
    for x = event.area.left_top.x, event.area.right_bottom.x - 1 do
        for y = event.area.left_top.y, event.area.right_bottom.y - 1 do
            table.insert(tiles, {name = 'lab-dark-1', position = {x, y}})
        end
    end
    event.surface.set_tiles(tiles)
end

function Public.run_combined_module(event)
    init()
    if event.surface.name == 'Zerus' then
        wrech_items_module.on_chunk_generated(event)
    elseif event.surface.name == 'Nihil' then
        generate_nihil(event)
    end
end

local function teleport_nearby_players(portal)
    for _, player_character in pairs(portal.source.find_entities_filtered {area = {{portal.position.x - storage.portal_radius, portal.position.y - storage.portal_radius}, {portal.position.x + storage.portal_radius, portal.position.y + storage.portal_radius}}, name = 'character', type = 'character'}) do
        local player = player_character.player
        if not storage.last_tp[player.name] or storage.last_tp[player.name] + storage.teleport_cooldown * 60 < game.tick then
            player.teleport(portal.target, portal.target_surface)
            storage.last_tp[player.name] = game.tick
            player.print('Wooosh! You are now in the ' .. portal.target_surface.name .. ' dimension.')
        end
    end
end

local function teleport_players()
    local num_portals = #storage.portals
    if num_portals > 0 then
        local portal = storage.portals[storage.current_portal_index]
        if portal.target then
            teleport_nearby_players(portal)
        end
        storage.current_portal_index = (storage.current_portal_index) % num_portals + 1 --Next portal
    end
end

local function teleport_stuff()
    local num_chests = #storage.magic_chests
    if num_chests > 0 then
        local chest = storage.magic_chests[storage.current_magic_chest_index]
        if chest.entity and chest.target and chest.entity.valid and chest.target.valid then
            local inv = chest.entity.get_inventory(defines.inventory.chest)
            local target_inv = chest.target.get_inventory(defines.inventory.chest)
            if inv and target_inv then
                for _, item_stack in pairs(inv.get_contents()) do
                    local n_inserted = target_inv.insert(item_stack)
                    if n_inserted > 0 then
                        inv.remove { name = item_stack.name, count = n_inserted, quality = item_stack.quality }
                    end
                end
            end
        end
        storage.current_magic_chest_index = (storage.current_magic_chest_index) % num_chests + 1 --Next magic chest
    end
end

local function dim_on_tick()
    if game.tick % 2 == 0 then
        teleport_stuff()
    else
        teleport_players()
    end
end

storage.chest_selected = false
local function linkchests()
    if game.player and game.player.admin and game.player.selected and (game.player.selected.type == 'logistic-container' or game.player.selected.type == 'container') then
        game.player.selected.destructible = false
        game.player.selected.minable_flag = false
        if storage.chest_selected then
            storage.magic_chests[#storage.magic_chests].target = game.player.selected
            game.print('Link established.')
        else
            table.insert(storage.magic_chests, {entity = game.player.selected})
            game.print('Selected first chest.')
        end
        storage.chest_selected = not storage.chest_selected
    else
        game.print('failed.')
    end
end

storage.portal_selected = false
local function linkportals()
    if game.player and game.player.admin then
        if storage.portal_selected then
            storage.portals[#storage.portals].target = game.player.position
            storage.portals[#storage.portals].target_surface = game.player.surface
            --Way back home:
            table.insert(storage.portals, {position = game.player.position, target = storage.portals[#storage.portals].position, source = game.player.surface, target_surface = storage.portals[#storage.portals].source})
            game.print('Portal link established.')
        else
            table.insert(storage.portals, {position = game.player.position, source = game.player.surface})
            game.print('Selected first portal.')
        end
        storage.portal_selected = not storage.portal_selected
    else
        game.print('failed.')
    end
end

commands.add_command('linkchests', 'Select a chest to link to another. Run this command again to select the other one.', linkchests) -- luacheck: ignore
commands.add_command('linkportals', 'Select a portal to link to another. Run this command again to select the other one.', linkportals) -- luacheck: ignore
Event.add(defines.events.on_tick, dim_on_tick)

return Public
