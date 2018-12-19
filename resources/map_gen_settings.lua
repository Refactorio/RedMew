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
    -- no cliffs, enemies high frequency, big size, starting area to small
    redmew_default = {
        autoplace_controls = {
            ['coal'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['copper-ore'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['crude-oil'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['enemy-base'] = {
                frequency = 'high',
                richness = 'normal',
                size = 'high'
            },
            ['iron-ore'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['stone'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['uranium-ore'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['desert'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['dirt'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['grass'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['sand'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['trees'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            }
        },
        cliff_settings = {
            cliff_elevation_0 = 1024,
            cliff_elevation_interval = 10,
            name = 'cliff'
        },
        terrain_segmentation = 'normal', -- water frequency
        water = 'normal', -- water size
        starting_area = 'low',
        starting_points = {
            {
                x = 0,
                y = 0
            }
        },
        width = 2000000,
        height = 2000000,
        peaceful_mode = false,
        seed = nil
    },
    -- no cliffs
    no_cliff = {
        {
            autoplace_controls = {
                coal = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['copper-ore'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['crude-oil'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                desert = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                dirt = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['enemy-base'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                grass = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['iron-ore'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                sand = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                stone = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                trees = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['uranium-ore'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                }
            },
            cliff_settings = {
                cliff_elevation_0 = 1024,
                cliff_elevation_interval = 10,
                name = 'cliff'
            },
            height = 2000000,
            peaceful_mode = false,
            seed = nil,
            starting_area = 'normal',
            starting_points = {
                {
                    x = 0,
                    y = 0
                }
            },
            terrain_segmentation = 'normal',
            water = 'normal',
            width = 2000000
        }
    },
    -- no cliffs, no ores/oil
    no_cliff_ore = {
        {
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
                desert = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                dirt = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['enemy-base'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                grass = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['iron-ore'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'none'
                },
                sand = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                stone = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'none'
                },
                trees = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['uranium-ore'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'none'
                }
            },
            cliff_settings = {
                cliff_elevation_0 = 1024,
                cliff_elevation_interval = 10,
                name = 'cliff'
            },
            height = 2000000,
            peaceful_mode = false,
            seed = nil,
            starting_area = 'normal',
            starting_points = {
                {
                    x = 0,
                    y = 0
                }
            },
            terrain_segmentation = 'normal',
            water = 'normal',
            width = 2000000
        }
    },
    -- no cliffs, no ores/oil, no water
    no_cliff_ore_water = {
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
            desert = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            dirt = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['enemy-base'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            grass = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['iron-ore'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            sand = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            stone = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            trees = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['uranium-ore'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            }
        },
        cliff_settings = {
            cliff_elevation_0 = 1024,
            cliff_elevation_interval = 10,
            name = 'cliff'
        },
        height = 2000000,
        peaceful_mode = false,
        seed = nil,
        starting_area = 'very-low',
        starting_points = {
            {
                x = 0,
                y = 0
            }
        },
        terrain_segmentation = 'normal',
        water = 'none',
        width = 2000000
    },
    -- no cliffs, no ores/oil, no water, no enemies
    no_cliff_ore_water_enemy = {
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
            desert = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            dirt = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['enemy-base'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            grass = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['iron-ore'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            sand = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            stone = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            trees = {
                frequency = 'normal',
                richness = 'normal',
                size = 'normal'
            },
            ['uranium-ore'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            }
        },
        cliff_settings = {
            cliff_elevation_0 = 1024,
            cliff_elevation_interval = 10,
            name = 'cliff'
        },
        height = 2000000,
        peaceful_mode = false,
        seed = nil,
        starting_area = 'very-low',
        starting_points = {
            {
                x = 0,
                y = 0
            }
        },
        terrain_segmentation = 'normal',
        water = 'none',
        width = 2000000
    },
    -- cliffs to very high frequency, very big size
    cliff_hell = {
        {
            autoplace_controls = {
                coal = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['copper-ore'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['crude-oil'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                desert = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                dirt = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['enemy-base'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                grass = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['iron-ore'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                sand = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                stone = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                trees = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                },
                ['uranium-ore'] = {
                    frequency = 'normal',
                    richness = 'normal',
                    size = 'normal'
                }
            },
            cliff_settings = {
                cliff_elevation_0 = 2.5000572204589844,
                cliff_elevation_interval = 2.5000572204589844,
                name = 'cliff'
            },
            height = 2000000,
            peaceful_mode = false,
            seed = nil,
            starting_area = 'normal',
            starting_points = {
                {
                    x = 0,
                    y = 0
                }
            },
            terrain_segmentation = 'normal',
            water = 'normal',
            width = 2000000
        }
    },
}
