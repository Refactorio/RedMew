-- dependencies
local ScenarioInfo = require 'features.gui.info'
local RS = require 'map_gen.shared.redmew_surface'
local Event = require 'utils.event'
local pairs = pairs
local type = type

local restart_command = require 'map_gen.maps.diggy.feature.restart_command'

require 'utils.table'
require 'utils.core'

-- this
local Scenario = {}

RS.set_first_player_position_check_override(true) -- forces players to spawn at 0,0
RS.set_spawn_island_tile('stone-path')
storage.diggy_scenario_registered = false

--[[--
    Allows calling a callback for each enabled feature.

    Signature: callback(feature_name, Table feature_data) from {@see Config.features}.

    @param if_enabled function to be called if enabled
]]
local function each_enabled_feature(diggy_config, if_enabled)
    local enabled_type = type(if_enabled)
    if ('function' ~= enabled_type) then
        error('each_enabled_feature expects callback to be a function, given type: ' .. enabled_type)
    end

    for current_name, feature_data in pairs(diggy_config.features) do
        if (nil == feature_data.enabled) then
            error('Feature ' .. current_name .. ' did not define the enabled property.')
        end

        if (feature_data.enabled) then
            if_enabled(current_name, feature_data)
        end
    end
end

---Register the events required to initialize the scenario.
function Scenario.register(diggy_config)
    if storage.diggy_scenario_registered then
        error('Cannot register the Diggy scenario multiple times.')
        return
    end

    -- disabled redmew features for diggy
    local redmew_config = storage.config
    redmew_config.market.enabled = false
    redmew_config.reactor_meltdown.enabled = false
    redmew_config.hodor.enabled = false
    redmew_config.paint.enabled = false
    redmew_config.experience.enabled = true

    restart_command({scenario_name = diggy_config.scenario_name})

    each_enabled_feature(
        diggy_config,
        function(feature_name, feature_config)
            local feature = feature_config.load()
            if ('function' ~= type(feature.register)) then
                error('Feature ' .. feature_name .. ' did not define a register function.')
            end

            feature.register(feature_config)

            if ('function' == type(feature.get_extra_map_info)) then
                ScenarioInfo.add_map_extra_info(feature.get_extra_map_info(feature_config) .. '\n')
            end

            if ('function' == type(feature.on_init)) then
                Event.on_init(feature.on_init)
            end
        end
    )

    storage.diggy_scenario_registered = true
end


return Scenario
