-- dependencies
local Event = require 'utils.event'
local Config = require 'map_gen.Diggy.Config'
local Debug = require 'map_gen.Diggy.Debug'

require 'utils.list_utils'
require 'utils.utils'

-- this
local Scenario = {}

-- private state
local scenario_registered = false
local scenario_initialized = false


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

--[[--
    Register the events required to initialize the scenario.
]]
function Scenario.register(debug)
    if scenario_registered then
        error('Cannot register the scenario multiple times.')
        return
    end

    -- using the on_player_created to initialize all the features
    Event.add(defines.events.on_player_created, function (event)
        if ('boolean' == type(debug)) then
            Config.Debug = debug
        end

        if (Config.debug) then
            Debug.enable_debug()
        end

        if (Config.cheats) then
            Debug.enable_cheats()
        end

        Scenario.initialize(Config)
    end)

    each_enabled_feature(function(feature_name, feature_data)
        if ('function' ~= type(feature_data.register)) then
            error('Feature ' .. feature_name .. ' did not define a register function.')
        end

        feature_data.register(Config)
    end)

    scenario_registered = true
end

--[[--
    Initializes the starting position.

    @param config Table {@see Diggy.Config}.
]]
function Scenario.initialize(config)
    if scenario_initialized then
        return
    end

    each_enabled_feature(function(feature_name, feature_data)
        if ('function' ~= type(feature_data.initialize)) then
            error('Feature ' .. feature_name .. ' did not define an initialize function.')
        end

        feature_data.initialize(config)
    end)

    scenario_initialized = true
end

return Scenario
