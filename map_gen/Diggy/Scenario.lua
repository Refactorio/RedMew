-- dependencies
local Config = require 'map_gen.Diggy.Config'
local ScenarioInfo = require 'features.gui.info'
local Event = require 'utils.event'

require 'utils.table'
require 'utils.core'

-- this
local Scenario = {}

global.diggy_scenario_registered = false

--[[--
    Allows calling a callback for each enabled feature.

    Signature: callback(feature_name, Table feature_data) from {@see Config.features}.

    @param if_enabled function to be called if enabled
]]
local function each_enabled_feature(if_enabled)
    local type = type(if_enabled)
    if ('function' ~= type) then
        error('each_enabled_feature expects callback to be a function, given type: ' .. type)
    end

    for current_name, feature_data in pairs(Config.features) do
        if (nil == feature_data.enabled) then
            error('Feature ' .. current_name .. ' did not define the enabled property.')
        end

        if (feature_data.enabled) then
            if_enabled(current_name, feature_data)
        end
    end
end

---Register the events required to initialize the scenario.
function Scenario.register()
    if global.diggy_scenario_registered then
        error('Cannot register the Diggy scenario multiple times.')
        return
    end

    global.config.player_list.enable_coin_col = false
    if global.config then
        global.config.fish_market.enable = nil
    end

    local extra_map_info = ''

    each_enabled_feature(
        function(feature_name, feature_config)
            local feature = require ('map_gen.Diggy.Feature.' .. feature_name)
            if ('function' ~= type(feature.register)) then
                error('Feature ' .. feature_name .. ' did not define a register function.')
            end

            feature.register(feature_config)

            if ('function' == type(feature.get_extra_map_info)) then
                extra_map_info = extra_map_info .. feature.get_extra_map_info(feature_config) .. '\n\n'
            end

            if ('function' == type(feature.on_init)) then
                Event.on_init(feature.on_init)
            end
        end
    )

    local landfill_tiles = {'dirt-1','dirt-2','dirt-3','dirt-4','dirt-5','dirt-6','dirt-7'}
    require ('map_gen.misc.change_landfill_tile')(landfill_tiles)

    ScenarioInfo.set_map_name('Diggy')
    ScenarioInfo.set_map_description('Dig your way through!')
    ScenarioInfo.set_map_extra_info(extra_map_info)

    global.diggy_scenario_registered = true
end

return Scenario
