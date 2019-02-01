-- dependencies
local Config = require 'map_gen.maps.diggy.config'
local ScenarioInfo = require 'features.gui.info'
local RS = require 'map_gen.shared.redmew_surface'
local Event = require 'utils.event'
local type = type
local pairs = pairs

require 'utils.table'
require 'utils.core'

-- this
local Scenario = {}

RS.set_first_player_position_check_override(true) -- forces players to spawn at 0,0
RS.set_spawn_island_tile('stone-path')
global.diggy_scenario_registered = false

--[[--
    Allows calling a callback for each enabled feature.

    Signature: callback(feature_name, Table feature_data) from {@see Config.features}.

    @param if_enabled function to be called if enabled
]]
local function each_enabled_feature(if_enabled)
    local enabled_type = type(if_enabled)
    if ('function' ~= enabled_type) then
        error('each_enabled_feature expects callback to be a function, given type: ' .. enabled_type)
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

    -- disabled redmew features for diggy
    local redmew_config = global.config
    redmew_config.market.enabled = false
    redmew_config.reactor_meltdown.enabled = false
    redmew_config.hodor.enabled = false
    redmew_config.paint.enabled = false

    each_enabled_feature(
        function(feature_name, feature_config)
            local feature = require ('map_gen.maps.diggy.feature.' .. feature_name)
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

    local landfill_tiles = {'dirt-1','dirt-2','dirt-3','dirt-4','dirt-5','dirt-6','dirt-7'}
    require ('map_gen.shared.change_landfill_tile')(landfill_tiles)

    ScenarioInfo.set_map_name('Diggy')
    ScenarioInfo.set_map_description('Dig your way through!')

    global.diggy_scenario_registered = true
end

return Scenario
