-- dependencies
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local ForceControl = require 'features.force_control'
local Debug = require 'map_gen.Diggy.Debug'

-- Will be registered in Experience.register
local ForceControl_builder = {}

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


local Config = {}
local string_format = string.format
local alien_coin_modifiers = require 'map_gen.Diggy.Config'.features.ArtefactHunting.alien_coin_modifiers

local level_up_formula = (function (level_reached)
    local floor = math.floor
    local log = math.log
    local Config = require 'map_gen.Diggy.Config'.features.Experience
    local difficulty_scale = floor(Config.difficulty_scale)
    local level_fine_tune = floor(Config.xp_fine_tune)
    local start_value = (floor(Config.first_lvl_xp)/2)
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
    lower_value = lower_value - (lower_value % (10 ^ (floor(log(lower_value,10)) - precision)))
    return value - lower_value
end)

---Updates a forces manual mining speed modifier. By removing active modifiers and re-adding
---@param force LuaForce the force of which will be updated
---@param level_up number a level if updating as part of a level up (optional)
function Experience.update_mining_speed(force, level_up)
    local level_up = level_up ~= nil and level_up or 0
    local buff = Config.buffs['mining_speed']
    if level_up > 0 and buff ~= nil then
        local value = (buff.double_level ~= nil and level_up%buff.double_level == 0) and buff.value*2 or buff.value
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
    local level_up = level_up ~= nil and level_up or 0
    local buff = Config.buffs['inventory_slot']
    if level_up > 0 and buff ~= nil then
        local value = (buff.double_level ~= nil and level_up%buff.double_level == 0) and buff.value*2 or buff.value
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
    local level_up = level_up ~= nil and level_up or 0
    local buff = Config.buffs['health_bonus']
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

---Awards experience when a rock has been mined
---@param event LuaEvent
local function on_player_mined_entity(event)
    local entity = event.entity
    local player_index = event.player_index
    local force = Game.get_player_by_index(player_index).force
    local exp
    if entity.name == 'sand-rock-big' then
        exp = sand_rock_xp
    elseif entity.name == 'rock-huge' then
        exp = rock_huge_xp
    else
        return
    end
    local text = string_format('+%d XP', exp)
    Game.print_player_floating_text_position(player_index, text, {r = 144, g = 202, b = 249},0, -0.5)
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
        local reward = Config.XP[name]
        award_xp = award_xp + reward
    end
    local exp = award_xp * research.research_unit_count
    local text = string_format('Research completed! +%d XP', exp)
    for _, p in pairs(game.connected_players) do
        local player_index = p.index
        Game.print_player_floating_text_position(player_index, text, {r = 144, g = 202, b = 249}, -1, -0.5)
    end
    ForceControl.add_experience(force, exp)


    local current_modifier = mining_efficiency.research_modifier
    local new_modifier = force.mining_drill_productivity_bonus * Config.mining_speed_productivity_multiplier * 0.5

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

---Awards experience when a rocket has been launched
---@param event LuaEvent
local function on_rocket_launched(event)
    local exp = Config.XP['rocket_launch']
    local force = event.force
    local text = string_format('Rocket launched! +%d XP', exp)
    for _, p in pairs(game.connected_players) do
        local player_index = p.index
        Game.print_player_floating_text_position(player_index, text, {r = 144, g = 202, b = 249},-1, -0.5)
    end
    ForceControl.add_experience(force, exp)
end

---Awards experience when a player kills an enemy, based on type of enemy
---@param event LuaEvent
local function on_entity_died (event)
    local entity = event.entity
    local force = entity.force

    if force.name ~= 'enemy' then
        return
    end

    local cause = event.cause

    if not cause or cause.type ~= 'player' or not cause.valid then
        return
    end
    local exp = Config.XP['enemy_killed'] * alien_coin_modifiers[entity.name]
    local text = string_format('Killed %s! + %d XP', entity.name, exp)
    local player_index = cause.player.index
    Game.print_player_floating_text_position(player_index, text, {r = 144, g = 202, b = 249},-1, -0.5)
    ForceControl.add_experience(force, exp)
end

---Deducts experience when a player respawns, based on a percentage of total experience
---@param event LuaEvent
local function on_player_respawned(event)
    local player = Game.get_player_by_index(event.player_index)
    local force = player.force
    local exp = ForceControl.remove_experience_percentage(force, Config.XP['death-penalty'], 50)
    local text = string_format('%s died! -%d XP', player.name, exp)
    for _, p in pairs(game.connected_players) do
        Game.print_player_floating_text_position(p.index, text, {r = 255, g = 0, b = 0},-1, -0.5)
    end
end

---Get list of defined buffs
---@return table with the same format as in the Diggy Config
---@see Diggy.Config.features.Experience.Buffs
function Experience.get_buffs()
    return Config.buffs
end

local level_table = {}
---Get experiment requirement for a given level
---Primarily used for the market GUI to display total experience required to unlock a specific item
---@param level number a number specifying the level
---@return number required total experience to reach supplied level
function Experience.calculate_level_xp(level)
    if level_table[level] == nil then
        local value
        if level == 1 then
            value = level_up_formula(level-1)
        else
            value = level_up_formula(level-1)+Experience.calculate_level_xp(level-1)
        end
        table.insert(level_table, level, value)
    end
    return level_table[level]
end

function Experience.register(cfg)
    Config = cfg

    --Adds the function on how to calculate level caps (When to level up)
    ForceControl_builder = ForceControl.register(level_up_formula)

    --Adds a function that'll be executed at every level up
    ForceControl_builder.register_on_every_level(function (level_reached, force)
        force.print(string_format('%s Leveled up to %d!', '## - ', level_reached))
        force.play_sound{path='utility/new_objective', volume_modifier = 1 }
        local Experience = require 'map_gen.Diggy.Feature.Experience'
        Experience.update_inventory_slots(force, level_reached)
        Experience.update_mining_speed(force, level_reached)
        Experience.update_health_bonus(force, level_reached)
        local MarketExchange = require 'map_gen.Diggy.Feature.MarketExchange'
        local market = MarketExchange.get_market()
        MarketExchange.update_market_contents(market, force)
        MarketExchange.update_gui()
    end)

    -- Events
    Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
    Event.add(defines.events.on_research_finished, on_research_finished)
    Event.add(defines.events.on_rocket_launched, on_rocket_launched)
    Event.add(defines.events.on_player_respawned, on_player_respawned)
    Event.add(defines.events.on_entity_died, on_entity_died)

    -- Prevents table lookup thousands of times
    sand_rock_xp = Config.XP['sand-rock-big']
    rock_huge_xp = Config.XP['rock-huge']
end

function Experience.on_init()
    --Adds the 'player' force to participate in the force control system.
    local force = game.forces.player
    ForceControl.register_force(force)
end

return Experience
