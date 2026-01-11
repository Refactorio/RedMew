-- This feature adds an experience leveling system based on ForceControl.lua
-- made by Linaori & SimonFlapse
-- modified by Valansch, grilledham, RedRafe
-- ======================================================= --

local config = require 'config'.experience
local Color = require 'resources.color_presets'
local Event = require 'utils.event'
local ForceControl = require 'features.force_control'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local math = require 'utils.math'
local Retailer = require 'features.retailer'
local RS = require 'map_gen.shared.redmew_surface'
local ScoreTracker = require 'utils.score_tracker'
local Settings = require 'utils.redmew_settings'
local Toast = require 'features.gui.toast'
local Utils = require 'utils.core'

local Public = {}

local add_experience = ForceControl.add_experience
local add_experience_percentage = ForceControl.add_experience_percentage
local disable_item = Retailer.disable_item
local enable_item = Retailer.enable_item
local get_force_data = ForceControl.get_force_data
local remove_experience_percentage = ForceControl.remove_experience_percentage
local set_item = Retailer.set_item

local floor = math.floor
local insert = table.insert
local max = math.max
local min = math.min
local round_sig = math.round_sig
local gain_xp_color = Color.light_sky_blue
local lose_xp_color = Color.red

local notify_name = 'notify_experience_level_up'
local experience_lost_name = 'experience-lost'
local on_bonuses, off_bonuses = '▼  Bonuses', '▲  Bonuses'
local on_rewards, off_rewards = '▼  Rewards', '▲  Rewards'
local force_sounds = {}
local level_table = {}
local gui_toggled = {}
local mining_efficiency = { active_modifier = 0, research_modifier = 0, level_modifier = 0 }
local inventory_slots = { active_modifier = 0, research_modifier = 0, level_modifier = 0 }
local health_bonus = { active_modifier = 0, research_modifier = 0, level_modifier = 0 }
local character_reach = { active_modifier = 0, research_modifier = 0, level_modifier = 0 }
local crafting_speed = { active_modifier = 0, research_modifier = 0, level_modifier = 0 }
local running_speed = { active_modifier = 0, research_modifier = 0, level_modifier = 0 }

-- Prevents table lookup thousands of times
local rock_big_xp = config.XP['big-rock']
local rock_huge_xp = config.XP['huge-rock']

Global.register(
    {
        mining_efficiency = mining_efficiency,
        inventory_slots = inventory_slots,
        health_bonus = health_bonus,
        force_sounds = force_sounds,
        gui_toggled = gui_toggled,
        level_table = level_table,
        character_reach = character_reach,
        crafting_speed = crafting_speed,
        running_speed = running_speed,
    },
    function(tbl)
        mining_efficiency = tbl.mining_efficiency
        inventory_slots = tbl.inventory_slots
        health_bonus = tbl.health_bonus
        force_sounds = tbl.force_sounds
        gui_toggled = tbl.gui_toggled
        level_table = tbl.level_table
        character_reach = tbl.character_reach
        crafting_speed = tbl.crafting_speed
        running_speed = tbl.running_speed
    end
)

Settings.register(notify_name, Settings.types.boolean, true, 'experience.notify_caption_short')
ScoreTracker.register(experience_lost_name, { 'experience.score_experience_lost' }, '[img=item.artillery-targeting-remote]')

local global_to_show = storage.config.score.global_to_show
global_to_show[#global_to_show + 1] = experience_lost_name

-- == HELPERS ==============================================================

--[[
    Given the parameters

    a: difficulty_scale
    b: xp_fine_tune
    c: first_lvl_xp

    The Level Up formula is defined as:
    Experience(L) = a•L^3 + b•L^2 + (c-a-b)•L + 1.15^(0.1•L)
]]
---A function to calculate level caps (When to level up)
local level_up_formula = function(level_reached)
    local difficulty_scale = floor(config.difficulty_scale)
    local fine_tune = floor(config.xp_fine_tune)
    local start_value = floor(config.first_lvl_xp)
    local precision = floor(config.cost_precision)

    local function formula(L)
        local L2 = L * L
        local L3 = L * L2
        return floor(difficulty_scale * L3 + fine_tune * L2 + (start_value - difficulty_scale - fine_tune) * L + 1.15 ^ (0.1 * L))
    end

    local value = formula(level_reached + 1)
    local lower_value = formula(level_reached)
    return round_sig(value - lower_value, precision)
end

---Get experience requirement for a given level
---Primarily used for the Experience GUI to display total experience required to unlock a specific item
---@param level number a number specifying the level
---@return number required total experience to reach supplied level
local function calculate_level_xp(level)
    if level_table[level] == nil then
        local value
        if level == 1 then
            value = level_up_formula(level - 1)
        else
            value = level_up_formula(level - 1) + calculate_level_xp(level - 1)
        end
        insert(level_table, level, value)
    end
    return level_table[level]
end

---Get a percentage of required experience between a level and the next level
---@param level number a number specifying the current level
---@return number a percentage of the required experience to level up from one level to the other
local function percentage_of_level_req(level, percentage)
    return level_up_formula(level) * percentage
end

---@param force LuaForce
local function play_level_up_sound(force)
    if not config.sound then
        return
    end
    if not helpers.is_valid_sound_path(config.sound.path or '') then
        return
    end
    if force_sounds[force.index] and game.tick < force_sounds[force.index] then
        return
    end
    force_sounds[force.index] = game.tick + (config.sound.duration or 20 * 60)
    for _, player in pairs(force.connected_players) do
        if Settings.get(player.index, notify_name) then
            player.play_sound(config.sound)
        end
    end
end

---@param parent LuaGuiElement
---@param caption string
---@param element string|table
local function label_pair(parent, caption, element)
    local flow = parent.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(flow, { vertical_align = 'center' })
    flow.add { type = 'label', style = 'semibold_caption_label', caption = caption .. ':' }
    return (type(element) == 'table') and flow.add(element) or flow.add { type = 'label', caption = element }
end

---@param item table item data
local function get_item_tooltip(item)
    return {
        '',
        '[font=var]Item: [/font]',
        {'?', {'entity-name.'..item.name}, {'item-name.'..item.name}, {'equipment-name.'..item.name} },
        '\n[font=var]Price: [/font]'..item.price..' [img=item/coin]',
        '\n[font=var]Unlocked at: [/font]'..Utils.comma_value(calculate_level_xp(item.level))..' XP'
    }
end

---@field buff table of buff config
---@field force LuaForce
---@field formula? function
---@field level_up? number
---@field modifier table of modifiers
---@field property string LuaForce::property to update
local function update_modifier(params)
    local buff = params.buff
    local force = params.force
    local formula = params.formula or function(p) return p.buff.value end
    local level_up = params.level_up or 0
    local modifier = params.modifier
    local property = params.property

    if not buff or force[property] >= (buff.max or math.huge) then
        return
    end
    if buff.level_interval and (level_up % buff.level_interval ~= 0) then
        return
    end
    if level_up > 0 then
        local value = formula(params)
        if buff.double_level and (level_up % buff.double_level) == 0 then
            value = 2 * value
        end
        modifier.level_modifier = modifier.level_modifier + value
    end

    -- remove the current buff
    local old_modifier = force[property] - modifier.active_modifier
    old_modifier = old_modifier >= 0 and old_modifier or 0

    -- update the active modifier
    modifier.active_modifier = modifier.research_modifier + modifier.level_modifier

    -- add the new active modifier to the non-buffed modifier
    force[property] = old_modifier + modifier.active_modifier
    if buff.max then
        force[property] = min(buff.max, force[property])
    end
end

-- == GUI =====================================================================

local main_frame_name = Gui.uid_name()
local main_button_name = Gui.uid_name()
local bonuses_button_name = Gui.uid_name()
local rewards_list_button_name = Gui.uid_name()

Public.update_main_frame = function(player)
    local frame = Gui.get_left_element(player, main_frame_name)
    if not frame or not frame.valid then
        return
    end

    local force_data = get_force_data('player')
    local data = Gui.get_data(frame)
    local current_level = force_data.current_level

    data.level.caption = current_level
    data.label.caption = Utils.comma_value(force_data.total_experience)
    data.label.tooltip = { 'experience.gui_total_xp', Utils.comma_value(force_data.total_experience) }
    data.progress.value = force_data.experience_percentage * 0.01
    data.progress.tooltip = { 'experience.gui_progress_bar', floor(force_data.experience_percentage * 100) * 0.01 }
    data.bonus_mining_speed.caption = '+ '..(player.force.manual_mining_speed_modifier * 100)..'%'
    data.bonus_inventory_slot.caption = '+ '..player.force.character_inventory_slots_bonus
    data.bonus_health_bonus.caption = '+ '..player.force.character_health_bonus..'%'
    data.bonus_character_reach.caption = '+ '..(player.force.character_reach_distance_bonus)
    data.bonus_crafting_speed.caption = '+ '..(player.force.manual_crafting_speed_modifier * 100)..'%'
    data.bonus_running_speed.caption = '+ '..(player.force.character_running_speed_modifier * 100)..'%'

    for _, row in pairs(data.reward_list.children) do
        for _, item in pairs(row.children) do
            if item.tags and item.tags.level then
                item.style = (current_level >= item.tags.level) and 'green_slot' or 'yellow_slot_button'
                item.style.size = 32
            end
        end
    end
end

Public.get_main_frame = function(player)
    local frame = Gui.get_left_element(player, main_frame_name)
    if frame and frame.valid then
        return Public.update_main_frame(player)
    end

    local data = {}
    frame = Gui.add_left_element(player, { name = main_frame_name, type = 'frame', direction = 'vertical' })
    Gui.set_style(frame, { maximal_width = 360 })

    local canvas = frame
        .add { type = 'flow', direction = 'vertical', style = 'vertical_flow' }
        .add { type = 'frame', direction = 'vertical', style = 'inside_shallow_frame_packed' }

    do -- Title
        local subheader = canvas.add { type = 'frame', style = 'subheader_frame' }
        Gui.set_style(subheader, { horizontally_stretchable = true })

        local flow = subheader.add { type = 'flow', direction = 'horizontal' }
        local label = flow.add({ type = 'label', caption = 'Experience', style = 'frame_title' })
        Gui.set_style(label, { left_margin = 4 })
    end

    local sp = canvas.add { type = 'scroll-pane', vertical_scroll_policy = 'auto-and-reserve-space' }
    Gui.set_style(sp, { padding = 12, maximal_height = 600 })
    do -- Level
        local content = sp.add { type = 'frame', direction = 'vertical', style = 'deep_frame_in_shallow_frame_for_description' }
        content.add { type = 'label', style = 'tooltip_heading_label_category', caption = '★ XP' }
        content.add { type = 'line', style = 'tooltip_category_line' }
        data.level = label_pair(content, 'Level', '---')
        data.label = label_pair(content, 'Total', '---')
        data.progress = label_pair(content, 'Progress', { type = 'progressbar' })
    end
    do -- Bonuses
        local toggled = gui_toggled[player.index].bonuses
        local label = sp.add { type = 'label', style = 'bold_label', caption = toggled and on_bonuses or off_bonuses, name = bonuses_button_name, tooltip = 'Hide/Show bonuses' }
        local deep = sp.add { type = 'frame', direction = 'vertical', style = 'deep_frame_in_shallow_frame_for_description' }
        Gui.set_style(deep, { padding = 0, minimal_height = 4 })

        local content = deep.add { type = 'flow', direction = 'vertical' }
        Gui.set_style(content, { padding = 8 })
        content.visible = toggled
        Gui.set_data(label, { list = content })

        local buffs = config.buffs
        content.add { type = 'label', style = 'tooltip_heading_label_category', caption = '✔ Bonuses' }
        content.add { type = 'line', style = 'tooltip_category_line' }
        data.bonus_mining_speed = label_pair(content, 'Manual mining speed', '---')
        data.bonus_inventory_slot = label_pair(content, 'Inventory slots', '---')
        data.bonus_health_bonus = label_pair(content, 'Max health', '---')
        data.bonus_character_reach = label_pair(content, 'Character reach', '---')
        data.bonus_crafting_speed = label_pair(content, 'Crafting speed', '---')
        data.bonus_running_speed = label_pair(content, 'Running speed', '---')
        data.bonus_mining_speed.tooltip = { 'experience.gui_buff_mining', buffs.mining_speed.value, buffs.mining_speed.max * 100 }
        data.bonus_inventory_slot.tooltip = { 'experience.gui_buff_inv', buffs.inventory_slot.value, buffs.inventory_slot.max }
        data.bonus_health_bonus.tooltip = { 'experience.gui_buff_health', buffs.health_bonus.value, buffs.health_bonus.max }
        data.bonus_character_reach.tooltip = { 'experience.gui_buff_character_reach', buffs.character_reach.value, buffs.character_reach.max }
        data.bonus_crafting_speed.tooltip = { 'experience.gui_buff_crafting_speed', buffs.crafting_speed.value * 100, buffs.crafting_speed.max * 100 }
        data.bonus_running_speed.tooltip = { 'experience.gui_buff_running_speed', buffs.running_speed.value * 100, buffs.running_speed.max * 100 }
    end
    do -- Rewards
        local toggled = gui_toggled[player.index].rewards
        local label = sp.add { type = 'label', style = 'bold_label', caption = toggled and on_rewards or off_rewards, name = rewards_list_button_name, tooltip = 'Hide/Show rewards' }
        local deep = sp.add { type = 'frame', style = 'deep_frame_in_shallow_frame_for_description', direction = 'vertical' }
        Gui.set_style(deep, { padding = 0, minimal_height = 4 })

        local last = {}
        local list = deep
            .add { type = 'scroll-pane', vertical_scroll_policy = 'dont-show-but-allow-scrolling' }
            .add { type = 'table', style = 'table_with_selection', column_count = 2 }
        list.visible = toggled
        Gui.set_data(label, { list = list })
        for _, item in pairs(config.unlockables) do
            if item.level ~= last.level then
                local row = list.add { type = 'flow', direction = 'horizontal' }
                Gui.set_style(row, { vertical_align = 'center' })

                local level = row.add { type = 'sprite-button', caption = item.level, style = 'transparent_slot', ignored_by_interaction = true }
                Gui.set_style(level, { size = 24, font_color = { 255, 255, 255 } })

                Gui.add_pusher(row)
                last.row = row
            end
            local button = last.row.add {
                type = 'sprite-button',
                sprite = 'item.'..item.name,
                number = item.price,
                style = 'slot_button',
                tooltip = get_item_tooltip(item),
                tags = { level = item.level }
            }
            Gui.set_style(button, { size = 32 })
            last.level = item.level
        end
        data.reward_list = list
    end
    Gui.set_data(frame, data)
    Public.update_main_frame(player)
end

Public.toggle_main_button = function(player)
    local frame = Gui.get_left_element(player, main_frame_name)
    local button = Gui.get_top_element(player, main_button_name)
    if frame then
        button.toggled = false
        Gui.destroy(frame)
    else
        button.toggled = true
        Public.get_main_frame(player)
    end
end

---Toggle the player's experience main window, required for Cutscene controller module
Public.toggle = function(event)
    Public.toggle_main_button(event.player)
end

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)
Gui.on_click(main_button_name, Public.toggle)
Gui.on_custom_close(main_frame_name, Public.toggle)
Gui.on_click(bonuses_button_name, function(event)
    local list = Gui.get_data(event.element).list
    list.visible = not list.visible
    event.element.caption = list.visible and on_bonuses or off_bonuses
    gui_toggled[event.player_index].bonuses = list.visible
end)
Gui.on_click(rewards_list_button_name, function(event)
    local list = Gui.get_data(event.element).list
    list.visible = not list.visible
    event.element.caption = list.visible and on_rewards or off_rewards
    gui_toggled[event.player_index].rewards = list.visible
end)

-- == EVENTS ==================================================================

---Awards experience when a rock has been mined (increases by 1 XP every 5th level)
local function on_player_mined_entity(event)
    local entity = event.entity
    local name = entity.name
    local player_index = event.player_index
    local force = game.get_player(player_index).force
    local level = get_force_data(force).current_level
    local exp = 0
    if name == 'big-rock' then
        exp = rock_big_xp + floor(level / 5)
    elseif name == 'huge-rock' then
        exp = rock_huge_xp + floor(level / 5)
    end

    if exp == 0 then
        return
    end

    local text = { '', '[img=entity/' .. name .. '] ', { 'experience.float_xp_gained_mine', exp } }
    local player = game.get_player(player_index)
    player.create_local_flying_text { text = text, color = gain_xp_color, position = player.position }
    add_experience(force, exp)
end

---Awards experience when a research has finished, based on ingredient cost of research
local function on_research_finished(event)
    local research = event.research
    local force = research.force
    local exp
    if research.research_unit_count_formula ~= nil then
        local force_data = get_force_data(force)
        exp = percentage_of_level_req(force_data.current_level, config.XP['infinity-research'])
    else
        local award_xp = 0
        for _, ingredient in pairs(research.research_unit_ingredients) do
            local name = ingredient.name
            local reward = config.XP[name]
            award_xp = award_xp + reward
        end
        exp = award_xp * research.research_unit_count
    end
    local text = { '', '[img=item/automation-science-pack] ', { 'experience.float_xp_gained_research', exp } }
    Game.create_local_flying_text { surface = RS.get_surface_name(), text = text, color = gain_xp_color, create_at_cursor = true }
    add_experience(force, exp)

    local current_modifier = mining_efficiency.research_modifier
    local new_modifier = force.mining_drill_productivity_bonus * config.mining_speed_productivity_multiplier * 0.5

    if (current_modifier == new_modifier) then
        -- something else was researched
        return
    end

    mining_efficiency.research_modifier = new_modifier
    inventory_slots.research_modifier = force.mining_drill_productivity_bonus * 50 -- 1 per level

    Public.update_inventory_slots(force, 0)
    Public.update_mining_speed(force, 0)
    Public.update_health_bonus(force, 0)
    Public.update_character_reach_bonus(force, 0)
    Public.update_crafting_speed_bonus(force, 0)
    Public.update_running_speed_bonus(force, 0)
end

---Awards experience when a rocket has been launched based on percentage of total experience
local function on_rocket_launched(event)
    local force = event.rocket.force
    local silo_surface = event.rocket_silo and event.rocket_silo.surface

    local exp = add_experience_percentage(force, config.XP['rocket_launch'], nil, config.XP['rocket_launch_max'])
    local text = { '', '[img=item/satellite] ', { 'experience.float_xp_gained_rocket', exp } }
    Game.create_local_flying_text { surface = silo_surface and silo_surface.index, text = text, color = gain_xp_color, create_at_cursor = true }
end

---Awards experience when a player kills an enemy, based on type of enemy
local function on_entity_died(event)
    local entity = event.entity
    local force = event.force
    local cause = event.cause
    local entity_name = entity.name

    -- For bot mining and turrets
    if not cause or not cause.valid or cause.type ~= 'character' then
        local exp = 0
        local floating_text_position

        -- stuff killed by the player force, but not the player
        if force and force.name == 'player' then
            if cause and (cause.name == 'artillery-turret' or cause.name == 'gun-turret' or cause.name == 'laser-turret' or cause.name == 'flamethrower-turret') then
                exp = config.XP['enemy_killed'] * (config.alien_experience_modifiers[entity_name] or 1)
                floating_text_position = cause.position
            else
                local level = get_force_data(force).current_level
                if entity_name == 'big-rock' then
                    exp = floor((rock_big_xp + level * 0.2) * 0.5)
                elseif entity_name == 'huge-rock' then
                    exp = floor((rock_huge_xp + level * 0.2) * 0.5)
                end
                floating_text_position = entity.position
            end
        end

        if exp > 0 then
            Game.create_local_flying_text({
                surface = entity.surface,
                position = floating_text_position,
                text = { '', '[img=entity/' .. entity_name .. '] ', { 'experience.float_xp_gained_kill', exp } },
                color = gain_xp_color,
            })
            add_experience(force, exp)
        end

        return
    end

    if entity.force.name ~= 'enemy' then
        return
    end

    local exp = config.XP['enemy_killed'] * (config.alien_experience_modifiers[entity.name] or 1)
    cause.player.create_local_flying_text {
        position = cause.player.position,
        text = { '', '[img=entity/' .. entity_name .. '] ', { 'experience.float_xp_gained_kill', exp } },
        color = gain_xp_color,
    }
    add_experience(force, exp)
end

---Deducts experience when a player respawns, based on a percentage of total experience
local function on_player_respawned(event)
    local player = game.get_player(event.player_index)
    local exp = remove_experience_percentage(player.force, config.XP['death-penalty'], 50)
    local text = { '', '[img=entity.character]', { 'experience.float_xp_drain', exp } }
    game.print({ 'experience.player_drained_xp', player.name, exp }, { color = lose_xp_color })
    Game.create_local_flying_text { surface = player.surface, text = text, color = lose_xp_color, create_at_cursor = true }
    ScoreTracker.change_for_global(experience_lost_name, exp)
end

local function on_player_created(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end

    Gui.add_top_element(player, {
        name = main_button_name,
        type = 'sprite-button',
        sprite = 'entity/market',
        tooltip = { 'experience.gui_experience_button_tip' },
    })
    gui_toggled[player.index] = {
        bonuses = true,
        rewards = false,
    }
end

local function on_player_removed(event)
    gui_toggled[event.player_index] = nil
end

---Updates the experience progress gui for every player that has it open
local function on_nth_tick()
    for _, player in pairs(game.connected_players) do
        Public.update_main_frame(player)
    end

    -- Resets buffs if they have been set to 0
    local force = game.forces.player
    Public.update_inventory_slots(force, 0)
    Public.update_mining_speed(force, 0)
    Public.update_health_bonus(force, 0)
    Public.update_character_reach_bonus(force, 0)
    Public.update_crafting_speed_bonus(force, 0)
    Public.update_running_speed_bonus(force, 0)
end

local function on_init()
    -- Adds the 'player' force to participate in the force control system.
    local force = game.forces.player
    ForceControl.register_force(force)

    table.sort(config.unlockables, function(a, b) return a.level < b.level end)

    local force_name = force.name
    for _, prototype in pairs(config.unlockables) do
        set_item(force_name, prototype)
    end

    Public.update_market_contents(force)
end

---A function that will be executed at every level up
local function on_level_reached(level_reached, force)
    Toast.toast_force(force, 10, { 'experience.toast_new_level', level_reached })
    Public.update_inventory_slots(force, level_reached)
    Public.update_mining_speed(force, level_reached)
    Public.update_health_bonus(force, level_reached)
    Public.update_character_reach_bonus(force, level_reached)
    Public.update_crafting_speed_bonus(force, level_reached)
    Public.update_running_speed_bonus(force, level_reached)
    Public.update_market_contents(force)
    play_level_up_sound(force)
end

-- == EXPERIENCE ==============================================================

---Updates the market contents based on the current level.
---@param force LuaForce the force which the unlocking requirement should be based of
Public.update_market_contents = function(force)
    local current_level = get_force_data(force).current_level
    local force_name = force.name
    for _, prototype in pairs(config.unlockables) do
        local prototype_level = prototype.level
        if current_level < prototype_level then
            disable_item(force_name, prototype.name, { 'experience.market_disabled', prototype_level })
        else
            enable_item(force_name, prototype.name)
        end
    end
end

---Updates a forces manual mining speed modifier. By removing active modifiers and re-adding
---@param force LuaForce the force of which will be updated
---@param level_up? number a level if updating as part of a level up
Public.update_mining_speed = function(force, level_up)
    update_modifier{
        buff = config.buffs['mining_speed'],
        force = force,
        formula = function(params)
            local level = get_force_data(params.force).current_level
            return 0.01 * floor(max(params.buff.value, 24 * 0.9 ^ (level ^ 0.5)))
        end,
        level_up = level_up,
        modifier = mining_efficiency,
        property = 'manual_mining_speed_modifier',
    }
end

---Updates a forces inventory slots. By removing active modifiers and re-adding
---@param force LuaForce the force of which will be updated
---@param level_up? number a level if updating as part of a level up
Public.update_inventory_slots = function(force, level_up)
    update_modifier{
        buff = config.buffs['inventory_slot'],
        force = force,
        level_up = level_up,
        modifier = inventory_slots,
        property = 'character_inventory_slots_bonus',
    }
end

---Updates a forces health bonus. By removing active modifiers and re-adding
---@param force LuaForce the force of which will be updated
---@param level_up? number a level if updating as part of a level up
Public.update_health_bonus = function(force, level_up)
    update_modifier{
        buff = config.buffs['health_bonus'],
        force = force,
        level_up = level_up,
        modifier = health_bonus,
        property = 'character_health_bonus',
    }
end

---Updates a forces reach bonus. By removing active modifiers and re-adding
---@param force LuaForce the force of which will be updated
---@param level_up? number a level if updating as part of a level up
Public.update_character_reach_bonus = function(force, level_up)
    update_modifier{
        buff = config.buffs['character_reach'],
        force = force,
        level_up = level_up,
        modifier = character_reach,
        property = 'character_reach_distance_bonus',
    }
    for _, reach_property in pairs({
        'character_build_distance_bonus',
        'character_item_drop_distance_bonus',
        'character_reach_distance_bonus',
        'character_resource_reach_distance_bonus',
        'character_item_pickup_distance_bonus'
    }) do
        force[reach_property] = force.character_reach_distance_bonus
    end
end

---Updates a forces crafting speed bonus. By removing active modifiers and re-adding
---@param force LuaForce the force of which will be updated
---@param level_up? number a level if updating as part of a level up
Public.update_crafting_speed_bonus = function(force, level_up)
    update_modifier{
        buff = config.buffs['crafting_speed'],
        force = force,
        level_up = level_up,
        modifier = crafting_speed,
        property = 'manual_crafting_speed_modifier',
    }
end

---Updates a forces running speed bonus. By removing active modifiers and re-adding
---@param force LuaForce the force of which will be updated
---@param level_up? number a level if updating as part of a level up
Public.update_running_speed_bonus = function(force, level_up)
    update_modifier{
        buff = config.buffs['running_speed'],
        force = force,
        level_up = level_up,
        modifier = running_speed,
        property = 'character_running_speed_modifier',
    }
end

-- ============================================================================

Event.on_init(on_init)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_player_removed, on_player_removed)
Event.on_nth_tick(61, on_nth_tick)

local ForceControlBuilder = ForceControl.register(level_up_formula)
ForceControlBuilder.register_on_every_level(on_level_reached)

return Public
