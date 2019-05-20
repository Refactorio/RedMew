---Scales technology price multiplier based on number of online players.
---It does so only when finished research
local Event = require 'utils.event'
local Global = require 'utils.global'

local config = global.config.research_scaling
local limit = config.limit
local scale_value = config.scale_value

local multipliers = {
    current_multiplier = 0,
    old_multiplier = 0,
    old_setting = 0
}

Global.register(
    {
        multipliers = multipliers
    },
    function(tbl)
        multipliers = tbl.multipliers
    end
)

local function update_research_cost()
    local player_count = #game.connected_players
    local setting = game.difficulty_settings.technology_price_multiplier
    local modifier = player_count * scale_value - scale_value
    -- if config.limit is enabled, make sure the modifier doesn't exceed the limit
    if limit ~= -1 then
        modifier = (modifier <= limit) and modifier or limit
    end

    -- keeping track of old and new multiplier
    multipliers.old_multiplier = multipliers.current_multiplier
    multipliers.current_multiplier = modifier

    -- setting new modifier by subtracting old multiplier from setting and adding the new
    if setting == multipliers.old_setting then
        modifier = setting - multipliers.old_multiplier + modifier
    else -- if the setting was changed in between add the modifier a new.
        modifier = setting + modifier
    end
    game.difficulty_settings.technology_price_multiplier = modifier
    multipliers.old_setting = modifier
end

Event.add(defines.events.on_research_finished, update_research_cost)
