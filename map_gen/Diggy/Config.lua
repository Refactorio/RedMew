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
            register = require 'map_gen.Diggy.Feature.StartingZone'.register,
            initialize = require 'map_gen.Diggy.Feature.StartingZone'.initialize,

            -- initial starting position size, values higher than 30 might break
            starting_size = 8,

            -- the daytime value used for cave lighting
            daytime = 0.5,
        },
        SetupPlayer = {
            enabled = true,
            register = require 'map_gen.Diggy.Feature.SetupPlayer'.register,
            initialize = require 'map_gen.Diggy.Feature.SetupPlayer'.initialize,
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
            enabled = false,
            register = require 'map_gen.Diggy.Feature.DiggyTilePressure'.register,
            initialize = require 'map_gen.Diggy.Feature.DiggyTilePressure'.initialize,
        },
        DiggyHole = {
            enabled = true,
            register = require 'map_gen.Diggy.Feature.DiggyHole'.register,
            initialize = require 'map_gen.Diggy.Feature.DiggyHole'.initialize,
        },
        DiggyCaveCollapse = {
            enabled = true,
            register = require 'map_gen.Diggy.Feature.DiggyCaveCollapse'.register,
            initialize = require 'map_gen.Diggy.Feature.DiggyCaveCollapse'.initialize,
            support_beam_entities = {
                ['stone-wall'] = 1,
                ['sand-rock-big'] = 1,
                ['out-of-map'] = 1,
            },
        },
        RefreshMap = {
            enabled = true,
            register = require 'map_gen.Diggy.Feature.RefreshMap'.register,
            initialize = require 'map_gen.Diggy.Feature.RefreshMap'.initialize,
        },
        SimpleRoomGenerator = {
            enabled = true,
            register = require 'map_gen.Diggy.Feature.SimpleRoomGenerator'.register,
            initialize = require 'map_gen.Diggy.Feature.SimpleRoomGenerator'.initialize,
        },
    },
}

return Config
