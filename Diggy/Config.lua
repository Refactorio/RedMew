-- dependencies

-- this
local Config = {
    -- enable debug mode, shows extra messages
    debug = true,

    -- allow cheats. Example: by default the player will have X mining speed
    cheats = true,

    -- a list of features to register and enable
    -- to disable a feature, change the flag
    features = {
        StartingZone = {
            enabled = true,
            register = require 'Diggy.Feature.StartingZone'.register,
            initialize = require 'Diggy.Feature.StartingZone'.initialize,

            -- initial starting position size, values higher than 30 might break
            starting_size = 8,

            -- the daytime value used for cave lighting
            daytime = 0.5,
        },
        SetupPlayer = {
            enabled = true,
            register = require 'Diggy.Feature.SetupPlayer'.register,
            initialize = require 'Diggy.Feature.SetupPlayer'.initialize,
            starting_items = {
                {name = 'steel-axe', count = 2},
                {name = 'submachine-gun', count = 1},
                {name = 'light-armor', count = 1},
                {name = 'firearm-magazine', count = 25},
                {name = 'stone-wall', count = 10},
            },
            cheats = {
                manual_mining_speed_modifier = 10,
            },
        },
        DiggyTilePressure = {
            enabled = true,
            register = require 'Diggy.Feature.DiggyTilePressure'.register,
            initialize = require 'Diggy.Feature.DiggyTilePressure'.initialize,
        },
        DiggyHole = {
            enabled = true,
            register = require 'Diggy.Feature.DiggyHole'.register,
            initialize = require 'Diggy.Feature.DiggyHole'.initialize,
        },
        DiggyCaveCollapse = {
            enabled = true,
            register = require 'Diggy.Feature.DiggyCaveCollapse'.register,
            initialize = require 'Diggy.Feature.DiggyCaveCollapse'.initialize,
            support_beam_entities = {
                ['stone-wall'] = 1,
                ['sand-rock-big'] = 1,
                ['out-of-map'] = 1,
            },
        },
        RefreshMap = {
            enabled = true,
            register = require 'Diggy.Feature.RefreshMap'.register,
            initialize = require 'Diggy.Feature.RefreshMap'.initialize,
        },
        SimpleRoomGenerator = {
            enabled = true,
            register = require 'Diggy.Feature.SimpleRoomGenerator'.register,
            initialize = require 'Diggy.Feature.SimpleRoomGenerator'.initialize,
        },
    },
}

return Config
