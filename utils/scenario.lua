-- dependencies
local Event = require 'utils.event'

require 'utils.table'
require 'utils.core'

global.scenario_loaded = false

return function (scenario_namespace, config)
    if global.scenario_loaded then
        error(format('Cannot register '%s' scenario multiple times.', scenario_namespace))
        return
    end

    for feature_name, feature_config in pairs(config.features) do
        if nil == feature_config.enabled then
            error(format('Feature %s did not define the enabled property.', feature_name))
        end

        if feature_config.enabled then
            local feature = require (scenario_namespace .. '.' .. feature_name)
            if 'function' ~= type(feature.register) then
                error(format('Feature %s did not define a register function.', feature_name))
            end

            feature.register(feature_config)

            if 'function' == type(feature.on_init) then
                Event.on_init(feature.on_init)
            end
        end
    end

    global.scenario_loaded = true
end
