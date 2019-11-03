local Retailer = require 'features.retailer'
local Events = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Global = require 'utils.global'
local ScoreTracker = require 'utils.score_tracker'
local MarketItems = require 'map_gen.maps.space_race.market_items'

local unlock_progress = {
    force_USA = {
        players_killed = 0,
        entities_killed = 0
    },
    force_USSR = {
        players_killed = 0,
        entities_killed = 0
    }
}

local saved_prices = {}

Global.register(
    {
        unlock_progress = unlock_progress,
        saved_prices = saved_prices
    },
    function(tbl)
        unlock_progress = tbl.unlock_progress
        saved_prices = tbl.saved_prices
    end
)

local config = require 'map_gen.maps.space_race.config'

local entity_kill_rewards = config.entity_kill_rewards
local entity_kill_rewards_default = entity_kill_rewards['default']

local entity_drop_amount = config.entity_drop_amount

local player_kill_reward = config.player_kill_reward

local research_tiers = {
    ['automation-science-pack'] = 1,
    ['logistic-science-pack'] = 2,
    ['military-science-pack'] = 3,
    ['chemical-science-pack'] = 4,
    ['production-science-pack'] = 5,
    ['utility-science-pack'] = 6
    --['space-science-pack'] = 7 -- Only researches mining productivity
}

local function check_research_tier(tech, tier)
    local ingredients = tech.research_unit_ingredients
    if tier <= 2 then
        return #ingredients == tier
    end
    for i = 1, #ingredients do
        if research_tiers[ingredients[i].name] > tier then
            return false
        end
    end
    return true
end

local function random_tech(tier, force, group_name)
    local techs = force.technologies
    local tech_unlocked = false
    local techs_left = false
    local tier_name = 'random-tier-' .. tier
    for _, technology in pairs(techs) do
        local in_tier = check_research_tier(technology, tier)
        if (in_tier and technology.researched == false and technology.enabled == true) then
            if not tech_unlocked then
                tech_unlocked = true
                technology.researched = true
                force.print('[technology=' .. technology.name .. '] has been purchased and unlocked!')
                local items = Retailer.get_items(group_name)
                items[tier_name].price = math.ceil(items[tier_name].price * 1.05)
            elseif tech_unlocked then
                techs_left = true
                break
            end
        end
    end
    if not techs_left then
        local items = Retailer.get_items(group_name)
        local price = items[tier_name].price
        saved_prices[force.name][tier_name] = price
        Retailer.remove_item(group_name, tier_name)
    end
end

local function check_heighest_tier(tech)
    local ingredients = tech.research_unit_ingredients
    local tier = 1
    for i = 1, #ingredients do
        local ingredient_tier = research_tiers[ingredients[i].name]
        tier = ingredient_tier > tier and ingredient_tier or tier
    end
    return tier
end

local function on_market_purchase(event)
    local item = event.item
    local name = item.name
    local player = event.player
    local force = player.force

    if name == 'tank' then
        player.insert('tank')
        game.print({'', '[color=yellow]Warning! ', {'entity-name.' .. name}, ' has been brought by ' .. force.name .. '![/color]'})
        return
    end

    local group_name = event.group_name
    local research = force.technologies[name]
    if research and research.valid then
        research.enabled = true
        Retailer.remove_item(group_name, name)
        local tier = check_heighest_tier(research)
        local tier_name = 'random-tier-' .. tier
        if not Retailer.get_items(group_name)[tier_name] then
            for _, prototype in pairs(MarketItems) do
                if prototype.name == tier_name then
                    prototype.price = saved_prices[force.name][tier_name]
                    Retailer.set_item(group_name, prototype)
                    break
                end
            end
        end
    end

    if item.type == 'random-research' then
        random_tech(tonumber(string.sub(item.name, -1)), force, group_name)
    end
end

Events.add(Retailer.events.on_market_purchase, on_market_purchase)

local spill_items =
    Token.register(
    function(data)
        data.surface.spill_item_stack(data.position, {name = 'coin', count = data.count}, true)
    end
)

local random = math.random

local function invert_force(force)
    local teams = remote.call('space-race', 'get_teams')

    local force_USSR = teams[2]
    local force_USA = teams[1]

    if force == force_USA then
        return force_USSR
    elseif force == force_USSR then
        return force_USA
    end
end

local unlock_reasons = {
    player_killed = 1,
    entity_killed = 2
}

local function unlock_market_item(force, item_name)
    local group_name

    local teams = remote.call('space-race', 'get_teams')

    local force_USSR = teams[2]
    local force_USA = teams[1]

    if force == force_USA then
        group_name = 'USA_market'
    elseif force == force_USSR then
        group_name = 'USSR_market'
    end
    if group_name then
        Retailer.enable_item(group_name, item_name)
        if not (item_name == 'tank') then
            Debug.print('Unlocked: ' .. item_name .. ' | For: ' .. group_name)
        end
    end
end

local function check_for_market_unlocks(force)
    local teams = remote.call('space-race', 'get_teams')

    local force_USSR = teams[2]
    local force_USA = teams[1]

    for research, conditions in pairs(config.disabled_research) do
        local _force = force
        local inverted = conditions.invert
        local unlocks = conditions.unlocks

        if inverted then
            _force = invert_force(_force)
        end

        if force == force_USA then
            if conditions.player <= unlock_progress.force_USA.players_killed or conditions.entity <= unlock_progress.force_USA.entities_killed then
                unlock_market_item(_force, research)
                if unlocks then
                    unlock_market_item(invert_force(_force), unlocks)
                end
            end
        elseif force == force_USSR then
            if conditions.player <= unlock_progress.force_USSR.players_killed or conditions.entity <= unlock_progress.force_USSR.entities_killed then
                unlock_market_item(_force, research)
                if unlocks then
                    unlock_market_item(invert_force(_force), unlocks)
                end
            end
        end
    end

    if force_USA.technologies.tanks.researched then
        unlock_market_item(force_USA, 'tank')
    end
    if force_USSR.technologies.tanks.researched then
        unlock_market_item(force_USSR, 'tank')
    end
end

local function update_unlock_progress(force, unlock_reason)
    local players_killed
    local entities_killed

    local teams = remote.call('space-race', 'get_teams')

    local force_USSR = teams[2]
    local force_USA = teams[1]

    if force == force_USA then
        players_killed = unlock_progress.force_USA.players_killed
        entities_killed = unlock_progress.force_USA.entities_killed
        if unlock_reason == unlock_reasons.player_killed then
            unlock_progress.force_USA.players_killed = players_killed + 1
        elseif unlock_reason == unlock_reasons.entity_killed then
            unlock_progress.force_USA.entities_killed = entities_killed + 1
        end
    elseif force == force_USSR then
        players_killed = unlock_progress.force_USSR.players_killed
        entities_killed = unlock_progress.force_USSR.entities_killed
        if unlock_reason == unlock_reasons.player_killed then
            unlock_progress.force_USSR.players_killed = players_killed + 1
        elseif unlock_reason == unlock_reasons.entity_killed then
            unlock_progress.force_USSR.entities_killed = entities_killed + 1
        end
    else
        return
    end

    check_for_market_unlocks(force)
end

-- Determines how many coins to drop when enemy entity dies based upon the entity_drop_amount table in config.lua
local function spill_coins(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local force = event.cause.force or event.force
    if not force or entity.force == force then
        return
    end

    local bounds = entity_drop_amount[entity.name]
    if not bounds then
        return
    end

    local chance = bounds.chance

    if chance == 0 then
        return
    end

    if chance == 1 or random() <= chance then
        local count = random(bounds.low, bounds.high)
        if count > 0 then
            Task.set_timeout_in_ticks(
                1,
                spill_items,
                {
                    count = count,
                    surface = entity.surface,
                    position = entity.position
                }
            )
        end
    end
end

local function insert_coins(event)
    local entity = event.entity

    if entity.type == 'character' then
        return
    end

    local force = entity.force
    local name = entity.name
    if name == 'rocket-silo' then
        remote.call('space-race', 'lost', force)
    end

    local teams = remote.call('space-race', 'get_teams')

    local force_USSR = teams[2]
    local force_USA = teams[1]

    if force ~= force_USSR and force ~= force_USA then
        return
    end

    local cause = event.cause
    local cause_force = event.force

    local count = config.entity_kill_rewards[name] or entity_kill_rewards_default

    if cause_force then
        if not (cause and cause.valid) then
            if not (force == force_USA or force == force_USSR) then
                return
            end
            Task.set_timeout_in_ticks(
                1,
                spill_items,
                {
                    count = math.floor(count / 2),
                    surface = entity.surface,
                    position = entity.position
                }
            )
            return
        end
    end

    if cause and cause.valid then
        if cause.prototype.name == 'character' then
            cause_force = cause.force
            if not (force == cause_force) then
                local coins_inserted = cause.insert({name = 'coin', count = count})
                local player = cause.player
                if player and player.valid then
                    ScoreTracker.change_for_player(player.index, 'coins-earned', coins_inserted)
                    update_unlock_progress(cause_force, unlock_reasons.entity_killed)
                end
            end
        end
    end
end

local function on_entity_died(event)
    spill_coins(event)
    insert_coins(event)
end

Events.add(defines.events.on_entity_died, on_entity_died)

local function on_player_died(event)
    local cause = event.cause
    if cause and cause.valid and cause.type == 'character' then
        local cause_force = cause.force
        if not (game.get_player(event.player_index).force == cause_force) then
            local coins_inserted = cause.insert({name = 'coin', count = player_kill_reward})
            ScoreTracker.change_for_player(cause.index, 'coins-earned', coins_inserted)
            update_unlock_progress(cause_force, unlock_reasons.player_killed)
        end
    end
end

Events.add(defines.events.on_player_died, on_player_died)

local function check_random_research_unlock(research)
    local tier = research_tiers[research.name]

    if tier then
        local force = research.force

        local teams = remote.call('space-race', 'get_teams')

        local force_USSR = teams[2]
        local force_USA = teams[1]

        local group_name

        if force == force_USA then
            group_name = 'USA_market'
        elseif force == force_USSR then
            group_name = 'USSR_market'
        end

        if group_name then
            Retailer.enable_item(group_name, 'random-tier-' .. tier)
        end
    end
end

local function on_research_finished(event)
    local research = event.research
    check_for_market_unlocks(research.force)
    check_random_research_unlock(research)
    remote.call('space-race', 'remove_recipes')
end

Events.add(defines.events.on_research_finished, on_research_finished)
