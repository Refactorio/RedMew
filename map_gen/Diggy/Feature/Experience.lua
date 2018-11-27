-- dependencies
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local ForceControl = require 'features.force_control'
local Debug = require 'map_gen.Diggy.Debug'
local Retailer = require 'features.retailer'
local Gui = require 'utils.gui'
local force_control = require 'features.force_control'
local utils = require 'utils.utils'
local format = string.format
local string_format = string.format
local floor = math.floor
local log = math.log
local insert = table.insert

-- hack
local alien_coin_modifiers = require 'map_gen.Diggy.Config'.features.ArtefactHunting.alien_coin_modifiers

-- this
local Experience = {}

local mining_efficiency = {
    active_modifier = 0,
    research_modifier = 0,
    level_modifier = 0,
}

local inventory_slots = {
    active_modifier = 0,
    research_modifier = 0,
    level_modifier = 0,
}

local health_bonus = {
    active_modifier = 0,
    research_modifier = 0,
    level_modifier = 0,
}

Global.register({
    mining_efficiency = mining_efficiency,
    inventory_slots = inventory_slots,
    health_bonus = health_bonus
}, function(tbl)
    mining_efficiency = tbl.mining_efficiency
    inventory_slots = tbl.inventory_slots
    health_bonus = tbl.health_bonus
end)

local config = {}

local gain_xp_color = {r = 144, g = 202, b = 249}
local lose_xp_color = {r = 255, g = 0, b = 0}
local unlocked_color = {r = 255, g = 255, b = 255}
local locked_color = {r = 127, g = 127, b = 127}

local level_up_formula = (function (level_reached)
    local Config = require 'map_gen.Diggy.Config'.features.Experience
    local difficulty_scale = floor(Config.difficulty_scale)
    local level_fine_tune = floor(Config.xp_fine_tune)
    local start_value = (floor(Config.first_lvl_xp) * 0.5)
    local precision = (floor(Config.cost_precision))
    local function formula(level)
        return (
            difficulty_scale * (level) ^ 3
            + (level_fine_tune + start_value) * (level) ^ 2
            + start_value * (level)
            - difficulty_scale * (level)
            - level_fine_tune * (level)
        )
    end
    local value = formula(level_reached + 1)
    local lower_value = formula(level_reached)
    value = value - (value % (10 ^ (floor(log(value,10)) - precision)))
    if lower_value == 0 then
        return value - lower_value
    end
    lower_value = lower_value - (lower_value % (10 ^ (floor(log(lower_value, 10)) - precision)))
    return value - lower_value
end)

---Updates the market contents based on the current level.
---@param force LuaForce the force which the unlocking requirement should be based of
function Experience.update_market_contents(force)
    local current_level = ForceControl.get_force_data(force).current_level
    local force_name = force.name
    for _, prototype in ipairs(config.unlockables) do
        if (current_level >= prototype.level) then
            Retailer.set_item(force_name, prototype.name, {coin = prototype.price})
        end
    end

    Retailer.ship_items(force_name)
end

---Updates a forces manual mining speed modifier. By removing active modifiers and re-adding
---@param force LuaForce the force of which will be updated
---@param level_up number a level if updating as part of a level up (optional)
function Experience.update_mining_speed(force, level_up)
    level_up = level_up ~= nil and level_up or 0
    local buff = config.buffs['mining_speed']
    if level_up > 0 and buff ~= nil then
        local level = ForceControl.get_force_data(force).current_level
        local adjusted_value = floor(math.max(buff.value, 24*0.9^level))
        local value = (buff.double_level ~= nil and level_up % buff.double_level == 0) and adjusted_value * 2 or adjusted_value
        mining_efficiency.level_modifier = mining_efficiency.level_modifier + (value * 0.01)
    end
    -- remove the current buff
    local old_modifier = force.manual_mining_speed_modifier - mining_efficiency.active_modifier

    -- update the active modifier
    mining_efficiency.active_modifier = mining_efficiency.research_modifier + mining_efficiency.level_modifier

    -- add the new active modifier to the non-buffed modifier
    force.manual_mining_speed_modifier = old_modifier + mining_efficiency.active_modifier
end

---Updates a forces inventory slots. By removing active modifiers and re-adding
---@param force LuaForce the force of which will be updated
---@param level_up number a level if updating as part of a level up (optional)
function Experience.update_inventory_slots(force, level_up)
    level_up = level_up ~= nil and level_up or 0
    local buff = config.buffs['inventory_slot']
    if level_up > 0 and buff ~= nil then
        local value = (buff.double_level ~= nil and level_up % buff.double_level == 0) and buff.value * 2 or buff.value
        inventory_slots.level_modifier = inventory_slots.level_modifier + value
    end

    -- remove the current buff
    local old_modifier = force.character_inventory_slots_bonus - inventory_slots.active_modifier

    -- update the active modifier
    inventory_slots.active_modifier = inventory_slots.research_modifier + inventory_slots.level_modifier

    -- add the new active modifier to the non-buffed modifier
    force.character_inventory_slots_bonus = old_modifier + inventory_slots.active_modifier
end

---Updates a forces inventory slots. By removing active modifiers and re-adding
---@param force LuaForce the force of which will be updated
---@param level_up number a level if updating as part of a level up (optional)
function Experience.update_health_bonus(force, level_up)
    level_up = level_up ~= nil and level_up or 0
    local buff = config.buffs['health_bonus']
    if level_up > 0 and buff ~= nil then
        local value = (buff.double_level ~= nil and level_up%buff.double_level == 0) and buff.value*2 or buff.value
        health_bonus.level_modifier = health_bonus.level_modifier + value
    end

    -- remove the current buff
    local old_modifier = force.character_health_bonus - health_bonus.active_modifier

    -- update the active modifier
    health_bonus.active_modifier = health_bonus.research_modifier + health_bonus.level_modifier

    -- add the new active modifier to the non-buffed modifier
    force.character_health_bonus = old_modifier + health_bonus.active_modifier
end

-- declaration of variables to prevent table lookups @see Experience.register
local sand_rock_xp
local rock_huge_xp

---Awards experience when a rock has been mined (increases by 1 XP every 5th level)
---@param event LuaEvent
local function on_player_mined_entity(event)
    local entity = event.entity
    local player_index = event.player_index
    local force = Game.get_player_by_index(player_index).force
    local level = ForceControl.get_force_data(force).current_level
    local exp
    if entity.name == 'sand-rock-big' then
        exp = sand_rock_xp + floor(level / 5)
    elseif entity.name == 'rock-huge' then
        exp = rock_huge_xp + floor(level / 5)
    else
        return
    end
    local text = string_format('+%d XP', exp)
    Game.print_player_floating_text_position(player_index, text, gain_xp_color,0, -0.5)
    ForceControl.add_experience(force, exp)
end

---Awards experience when a research has finished, based on ingredient cost of research
---@param event LuaEvent
local function on_research_finished(event)
    local research = event.research
    local force = research.force
    local award_xp = 0

    for _, ingredient in pairs(research.research_unit_ingredients) do
        local name = ingredient.name
        local reward = config.XP[name]
        award_xp = award_xp + reward
    end
    local exp = award_xp * research.research_unit_count
    local text = string_format('Research completed! +%d XP', exp)
    for _, p in pairs(game.connected_players) do
        local player_index = p.index
        Game.print_player_floating_text_position(player_index, text, gain_xp_color, -1, -0.5)
    end
    ForceControl.add_experience(force, exp)


    local current_modifier = mining_efficiency.research_modifier
    local new_modifier = force.mining_drill_productivity_bonus * config.mining_speed_productivity_multiplier * 0.5

    if (current_modifier == new_modifier) then
        -- something else was researched
        return
    end

    mining_efficiency.research_modifier = new_modifier
    inventory_slots.research_modifier = force.mining_drill_productivity_bonus * 50 -- 1 per level

    Experience.update_inventory_slots(force, 0)
    Experience.update_mining_speed(force, 0)

    game.forces.player.technologies['landfill'].enabled = false
end

---Awards experience when a rocket has been launched based on percentage of total experience
---@param event LuaEvent
local function on_rocket_launched(event)
    local force = event.rocket.force
    local exp = ForceControl.add_experience_percentage(force, config.XP['rocket_launch'])
    local text = string_format('Rocket launched! +%d XP', exp)
    for _, p in pairs(game.connected_players) do
        local player_index = p.index
        Game.print_player_floating_text_position(player_index, text, gain_xp_color,-1, -0.5)
    end
end

---Awards experience when a player kills an enemy, based on type of enemy
---@param event LuaEvent
local function on_entity_died (event)
    local entity = event.entity
    local force = event.force
    local cause = event.cause

    --For bot mining and turrets
    if not cause or cause.type ~= 'player' or not cause.valid then
        local exp
        if force and force.name == 'player' then
            if cause and (cause.name == 'artillery-turret' or cause.name == 'gun-turret' or cause.name == 'laser-turret' or cause.name == 'flamethrower-turret') then
                exp = config.XP['enemy_killed'] * alien_coin_modifiers[entity.name]
                local text = string_format('+ %d XP', exp)
                Game.print_floating_text(cause.surface, cause.position, text, gain_xp_color)
                ForceControl.add_experience(force, exp)
                return
            else
                local level = ForceControl.get_force_data(force).current_level
                if entity.name == 'sand-rock-big' then
                    exp = floor((sand_rock_xp + (level / 5)) / 2)
                elseif entity.name == 'rock-huge' then
                    exp = floor((rock_huge_xp + (level / 5)) / 2)
                else
                    return
                end
            end
        end
        if exp then
            local text = string_format('+ %d XP', exp)
            Game.print_floating_text(entity.surface, entity.position, text, gain_xp_color)
            ForceControl.add_experience(force, exp)
        end
        return
    end

    if entity.force.name ~= 'enemy' then
        return
    end
    local exp = config.XP['enemy_killed'] * alien_coin_modifiers[entity.name]
    local text = string_format('+ %d XP', exp)
    local player_index = cause.player.index
    Game.print_player_floating_text_position(player_index, text, gain_xp_color,-1, -0.5)
    ForceControl.add_experience(force, exp)
end

---Deducts experience when a player respawns, based on a percentage of total experience
---@param event LuaEvent
local function on_player_respawned(event)
    local player = Game.get_player_by_index(event.player_index)
    local force = player.force
    local exp = ForceControl.remove_experience_percentage(force, config.XP['death-penalty'], 50)
    local text = string_format('%s resurrected! -%d XP', player.name, exp)
    for _, p in pairs(game.connected_players) do
        Game.print_player_floating_text_position(p.index, text, lose_xp_color, -1, -0.5)
    end
end

local level_table = {}
---Get experiment requirement for a given level
---Primarily used for the Experience GUI to display total experience required to unlock a specific item
---@param level number a number specifying the level
---@return number required total experience to reach supplied level
local function calculate_level_xp(level)
    if level_table[level] == nil then
        local value
        if level == 1 then
            value = level_up_formula(level-1)
        else
            value = level_up_formula(level-1)+calculate_level_xp(level-1)
        end
        insert(level_table, level, value)
    end
    return level_table[level]
end
local function redraw_title(data)
    local force_data = force_control.get_force_data('player')
    data.frame.caption = utils.comma_value(force_data.total_experience) .. ' total experience earned!'
end

local function apply_heading_style(style, width)
    style.font = 'default-bold'
    style.width = width
end

local function redraw_heading(data, header)
    local head_condition = (header == 1)
    local frame = (head_condition) and data.experience_list_heading or data.buff_list_heading
    local header_caption = (head_condition) and 'Reward Item' or 'Reward Buff'
    Gui.clear(frame)

    local heading_table = frame.add({type = 'table', column_count = 2})
    apply_heading_style(heading_table.add({ type = 'label', caption = 'Requirement'}).style, 100)
    apply_heading_style(heading_table.add({type = 'label', caption = header_caption}).style, 220)
end

local function redraw_progressbar(data)
    local force_data = force_control.get_force_data('player')
    local flow = data.experience_progressbars
    Gui.clear(flow)

    apply_heading_style(flow.add({type = 'label', tooltip = 'Currently at level: ' .. force_data.current_level .. '\nNext level at: ' .. utils.comma_value((force_data.total_experience - force_data.current_experience) + force_data.experience_level_up_cap) ..' xp\nRemaining xp: ' .. utils.comma_value(force_data.experience_level_up_cap - force_data.current_experience), name = 'Diggy.Experience.Frame.Progress.Level', caption = 'Progress to next level:'}).style)
    local level_progressbar = flow.add({type = 'progressbar', tooltip = floor(force_data.experience_percentage*100)*0.01 .. '% xp to next level'})
    level_progressbar.style.width = 350
    level_progressbar.value = force_data.experience_percentage * 0.01
end

local function redraw_table(data)
    local experience_scroll_pane = data.experience_scroll_pane
    Gui.clear(experience_scroll_pane)

    redraw_progressbar(data)
    redraw_heading(data, 1)

    local last_level = 0
    local current_force_level = force_control.get_force_data('player').current_level

    for _, prototype in ipairs(config.unlockables) do
        local current_item_level = prototype.level
        local first_item_for_level = current_item_level ~= last_level
        local color

        if current_force_level >= current_item_level  then
            color = unlocked_color
        else
            color = locked_color
        end

        local list = experience_scroll_pane.add({type = 'table', column_count = 2})

        local level_caption = ''
        if first_item_for_level then
            level_caption = 'level ' .. current_item_level
        end

        local level_column = list.add({
            type = 'label',
            caption = level_caption,
            tooltip = 'XP: ' .. utils.comma_value(calculate_level_xp(current_item_level)),
        })
        level_column.style.minimal_width = 100
        level_column.style.font_color = color

        local item_column = list.add({
            type = 'label',
            caption = prototype.name
        })
        item_column.style.minimal_width = 22
        item_column.style.font_color = color

        last_level = current_item_level
    end
end

local function redraw_buff(data)
    local buff_scroll_pane = data.buff_scroll_pane
    Gui.clear(buff_scroll_pane)

    local all_levels_shown = false
    for name, effects in pairs(config.buffs) do
        local list = buff_scroll_pane.add({type = 'table', column_count = 2})
        list.style.horizontal_spacing = 16

        local level_caption = ''
        if not all_levels_shown then
            all_levels_shown = true
            level_caption = 'All levels'
        end

        local level_label = list.add({type = 'label', caption = level_caption})
        level_label.style.minimal_width = 100
        level_label.style.font_color = unlocked_color

        local buff_caption
        local effect_value = effects.value
        if name == 'mining_speed' then
            buff_caption = format('+ %d mining speed', effect_value)
        elseif name == 'inventory_slot' then
            buff_caption = format('+ %d inventory slot%s', effect_value, effect_value > 1 and 's' or '')
        elseif name == 'health_bonus' then
            buff_caption = format('+ %d max health', effect_value)
        else
            buff_caption = format('+ %d %s', effect_value, name)
        end

        local buffs_label = list.add({ type = 'label', caption = buff_caption})
        buffs_label.style.minimal_width = 220
        buffs_label.style.font_color = unlocked_color
    end
end

local function toggle(event)
    local player = event.player
    local left = player.gui.left
    local frame = left['Diggy.Experience.Frame']

    if (frame and event.trigger == nil) then
        Gui.destroy(frame)
        return
    elseif (frame) then
        local data = Gui.get_data(frame)
        redraw_title(data)
        redraw_progressbar(data)
        redraw_table(data)
        return
    end

    frame = left.add({name = 'Diggy.Experience.Frame', type = 'frame', direction = 'vertical'})

    local experience_progressbars = frame.add({ type = 'flow', direction = 'vertical'})
    local experience_list_heading = frame.add({type = 'flow', direction = 'horizontal'})

    local experience_scroll_pane = frame.add({ type = 'scroll-pane'})
    experience_scroll_pane.style.maximal_height = 300

    local buff_list_heading = frame.add({type = 'flow', direction = 'horizontal'})

    local buff_scroll_pane = frame.add({type = 'scroll-pane'})
    buff_scroll_pane.style.maximal_height = 100

    frame.add({type = 'button', name = 'Diggy.Experience.Button', caption = 'Close'})

    local data = {
        frame = frame,
        experience_progressbars = experience_progressbars,
        experience_list_heading = experience_list_heading,
        experience_scroll_pane = experience_scroll_pane,
        buff_list_heading = buff_list_heading,
        buff_scroll_pane = buff_scroll_pane,
    }

    redraw_title(data)
    redraw_table(data)

    redraw_heading(data, 2)
    redraw_buff(data)

    Gui.set_data(frame, data)
end

local function on_player_created(event)
    Game.get_player_by_index(event.player_index).gui.top.add({
        name = 'Diggy.Experience.Button',
        type = 'sprite-button',
        sprite = 'entity/market',
    })
end

Gui.on_click('Diggy.Experience.Button', toggle)
Gui.on_custom_close('Diggy.Experience.Frame', function (event)
    event.element.destroy()
end)

---Updates the experience progress gui for every player that has it open
local function update_gui()
    for _, p in ipairs(game.connected_players) do
        local frame = p.gui.left['Diggy.Experience.Frame']

        if frame and frame.valid then
            local data = {player = p, trigger = 'update_gui'}
            toggle(data)
        end
    end
end

function Experience.register(cfg)
    config = cfg

    --Adds the function on how to calculate level caps (When to level up)
    local ForceControlBuilder = ForceControl.register(level_up_formula)

    --Adds a function that'll be executed at every level up
    ForceControlBuilder.register_on_every_level(function (level_reached, force)
        force.print(string_format('%s Leveled up to %d!', '## - ', level_reached))
        force.play_sound{path='utility/new_objective', volume_modifier = 1 }
        local Experience = require 'map_gen.Diggy.Feature.Experience'
        Experience.update_inventory_slots(force, level_reached)
        Experience.update_mining_speed(force, level_reached)
        Experience.update_health_bonus(force, level_reached)
        Experience.update_market_contents(force)
    end)

    -- Events
    Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
    Event.add(defines.events.on_research_finished, on_research_finished)
    Event.add(defines.events.on_rocket_launched, on_rocket_launched)
    Event.add(defines.events.on_player_respawned, on_player_respawned)
    Event.add(defines.events.on_entity_died, on_entity_died)
    Event.add(defines.events.on_player_created, on_player_created)
    Event.on_nth_tick(61, update_gui)

    -- Prevents table lookup thousands of times
    sand_rock_xp = config.XP['sand-rock-big']
    rock_huge_xp = config.XP['rock-huge']
end

function Experience.on_init()
    --Adds the 'player' force to participate in the force control system.
    local force = game.forces.player
    ForceControl.register_force(force)
end

return Experience
