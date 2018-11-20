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
local floor = math.floor
--local force = 'player'
local XP_text = ' XP'

function Experience.update_mining_speed(force, level_up)
    local buff = Config.buffs['mining_speed']
    if level_up > 0 and buff ~= nil then
        local value = (buff.double_level ~= nil and level_up%buff.double_level == 0) and buff.value*2 or buff.value
        mining_efficiency.level_modifier = mining_efficiency.level_modifier + (value / 100)
    end
    -- remove the current buff
    local old_modifier = force.manual_mining_speed_modifier - mining_efficiency.active_modifier

    -- update the active modifier
    mining_efficiency.active_modifier = mining_efficiency.research_modifier + mining_efficiency.level_modifier

    -- add the new active modifier to the non-buffed modifier
    force.manual_mining_speed_modifier = old_modifier + mining_efficiency.active_modifier
end

function Experience.update_inventory_slots(force, level_up)
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

function Experience.update_health_bonus(force, level_up)
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


local function on_player_mined_entity(event)
    local entity = event.entity
    local player_index = event.player_index
    local force = Game.get_player_by_index(player_index).force
    local text = ''
    local exp = 0
    if entity.name == 'sand-rock-big' then
        exp = 5
        text = '+' .. exp .. XP_text
    elseif entity.name == 'rock-huge' then
        exp = 10
        text = '+' .. exp .. XP_text
    else
        return
    end
    Game.print_player_floating_text_position(player_index, text, {r = 144, g = 202, b = 249},0, -0.5)
    ForceControl.add_experience(force, exp)

    Debug.print(ForceControl.get_formatted_force_data(force))
end

local function on_research_finished(event)
    local research = event.research
    local force = research.force
    local award_xp = 0
    for _, ingredient in pairs(research.research_unit_ingredients) do
        local reward = 0
        local name = ingredient.name
        if name == 'science-pack-1' then
            reward = 1
        elseif name == 'science-pack-2' then
            reward = 2
        elseif name == 'science-pack-3' then
            reward = 5
        elseif name == 'military-science-pack' then
            reward = 4
        elseif name == 'production-science-pack' then
            reward = 12
        elseif name == 'high-tech-science-pack' then
            reward = 25
        elseif name == 'space-science-pack' then
            reward = 5
        end
        award_xp = award_xp + reward
    end
    local exp = award_xp * research.research_unit_count
    local text = 'Research completed! +' .. exp .. XP_text
    for _, p in pairs(game.connected_players) do
        player_index = p.index
        Game.print_player_floating_text_position(player_index, text, {r = 144, g = 202, b = 249},-1, -0.5)
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

    Experience.update_inventory_slots(force, false)
    Experience.update_mining_speed(force, false)
end

local function on_rocket_launched(event)
    local exp = 5000
    local force = event.force
    local text = 'Rocket launched! +'.. exp .. XP_text
    for _, p in pairs(game.connected_players) do
        player_index = p.index
        Game.print_player_floating_text_position(player_index, text, {r = 144, g = 202, b = 249},-1, -0.5)
    end
    ForceControl.add_experience(force, exp)
end

local function on_player_died(event)
    local force = event.force
    ForceControl.remove_experience(force, 50)
    local player = Game.get_player_by_index(event.player_index)

    ForceControl.get_force_data(force)

    local exp = ForceControl.get_force_data(force).total_experience*0.005
    exp = (exp < 50) and 50 or exp
    local text = player.name..' died! -50'..XP_text
    for _, p in pairs(game.connected_players) do
        player_index = p.index
        Game.print_player_floating_text_position(player_index, text, {r = 255, g = 0, b = 0},-1, -0.5)
    end
    ForceControl.remove_experience(force, exp)
end


function Experience.register(cfg)
    Config = cfg
    local b = floor(Config.difficulty_scale) or 25 -- Default 25 <-- Controls how much stone is needed.
    local start_value = floor(Config.start_stone) or 50 -- The start value/the first level cost

    ForceControl_builder = ForceControl.register(function (level_reached)
        if level_reached ~= 0 then
            return b*((level_reached+1)^3)+(start_value-b) - (b*((level_reached)^3)+(start_value-b))
        else
            return b*((level_reached+1)^3)+(start_value-b)
        end
    end)

    ForceControl_builder.register_on_every_level(function (level_reached, force)
        force.print('Leved up to ' .. level_reached .. '!')
        force.play_sound{path='utility/new_objective', volume_modifier = 1 }
        local Experience = require 'map_gen.Diggy.Feature.Experience'
        Experience.update_inventory_slots(force, level_reached)
        Experience.update_mining_speed(force, level_reached)
        Experience.update_health_bonus(force, level_reached)
    end)

    -- Events
    Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
    Event.add(defines.events.on_research_finished, on_research_finished)
    Event.add(defines.events.on_rocket_launched, on_rocket_launched)
    Event.add(defines.events.on_player_respawned, on_player_died)

end

function Experience.on_init()
    local force = game.forces.player
    ForceControl.register_force(force)
    log(force.name)
end

return Experience
