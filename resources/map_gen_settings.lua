--[[ The easiest way to create a preset to add to this file is to use factorio itself. Create a new world
    (vanilla, not scenario) and configure the settings you want. When you launch the game, you can run the following:
    /c
    local str = serpent.block(game.surfaces.nauvis.map_gen_settings)
    game.write_file('map_gen_settings.lua', str)

    This will output a file with a table that you can add to this resources file or into your specific map.
    In either case, make sure to set seed to nil unless you want your map to be *exactly* the same each time.
    The expectation is that all changes that deviate from default generation are noted.
]]
return {
    -- high frequency and big size enemies
    enemy_high = {
        autoplace_controls = {
            ['enemy-base'] = {
                frequency = 'high',
                richness = 'normal',
                size = 'high'
            }
        }
    },
    -- no ores/oil
    ore_none = {
        autoplace_controls = {
            coal = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            ['copper-ore'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            ['crude-oil'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            ['iron-ore'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            stone = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            ['uranium-ore'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            }
        }
    },
    -- no water
    water_none = {
        terrain_segmentation = 'normal',
        water = 'none'
    },
    -- no enemies
    enemy_none = {
        autoplace_controls = {
            ['enemy-base'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            }
        }
    },
    -- no cliffs
    cliff_none = {
        cliff_settings = {
            cliff_elevation_0 = 1024,
            cliff_elevation_interval = 10,
            name = 'cliff'
        }
    },
    -- cliffs to very high frequency, very big size
    cliff_very_high = {
        cliff_settings = {
            cliff_elevation_0 = 2.5000572204589844,
            cliff_elevation_interval = 2.5000572204589844,
            name = 'cliff'
        }
    },
}
