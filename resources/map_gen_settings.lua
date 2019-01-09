--[[ The easiest way to create a preset to add to this file is to use factorio itself. Create a new world
    (vanilla, not scenario) and configure the settings you want. When you launch the game, you can run the following:
    /c
    local str = serpent.block(game.surfaces.nauvis.map_gen_settings)
    game.write_file('map_gen_settings.lua', str)

    This will output a file with a table that you can add to this resources file or into your specific map.
    In either case, make sure to set seed to nil unless you want your map to be *exactly* the same each time.
    The expectation is that all changes that deviate from default generation are noted.
    Water size and frequency is not denoted as such. Instead water size = water and water frequency = terrain_segmentation
]]
return {
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
    -- very high frequency and very big size enemies
    enemy_very_high = {
        autoplace_controls = {
            ['enemy-base'] = {
                frequency = 'very-high',
                richness = 'normal',
                size = 'very-high'
            }
        }
    },
    -- no ores
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
    -- no oil
    oil_none = {
        autoplace_controls = {
            ['crude-oil'] = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            }
        }
    },
    -- no ores, no oil
    ore_oil_none = {
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
    -- very low water
    water_very_low = {
        terrain_segmentation = 'very-low',
        water = 'very-low'
    },
    -- no cliffs
    cliff_none = {
        cliff_settings = {
            cliff_elevation_0 = 1024,
            cliff_elevation_interval = 10,
            name = 'cliff'
        }
    },
    -- normal cliffs
    cliff_normal = {
        name = 'cliff',
        cliff_elevation_0 = 10,
        cliff_elevation_interval = 10
    },
    -- cliffs to very high frequency, very big size
    cliff_very_high = {
        cliff_settings = {
            cliff_elevation_0 = 2.5000572204589844,
            cliff_elevation_interval = 2.5000572204589844,
            name = 'cliff'
        }
    },
    -- cliffs to very high frequency, very big size
    tree_none = {
        autoplace_controls = {
            trees = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            }
        }
    },
    -- cliffs to very high frequency, very big size
    tree_very_high = {
        autoplace_controls = {
            trees = {
                frequency = 'very-high',
                richness = 'very-high',
                size = 'very-high'
            }
        }
    },
    -- starting area to very low
    starting_area_very_low = {
        starting_area = 'very-low'
    },
    -- peaceful mode on
    peaceful_mode_on = {
        peaceful_mode = false
    },
    -- random seed, in case you need/want the seed to be unique from nauvis
    unique_seed = {
        seed = nil
    },
    -- grass only
    grass_only = {
        autoplace_controls = {
            grass = {frequency = 'normal', size = 'normal', richness = 'normal'},
            desert = {frequency = 'normal', size = 'none', richness = 'normal'},
            dirt = {frequency = 'normal', size = 'none', richness = 'normal'},
            sand = {frequency = 'normal', size = 'none', richness = 'normal'}
        },
    },
    -- desert only
    desert_only = {
        autoplace_controls = {
            grass = {frequency = 'normal', size = 'none', richness = 'normal'},
            desert = {frequency = 'normal', size = 'normal', richness = 'normal'},
            dirt = {frequency = 'normal', size = 'none', richness = 'normal'},
            sand = {frequency = 'normal', size = 'none', richness = 'normal'}
        },
    },
    -- dirt only
    dirt_only = {
        autoplace_controls = {
            grass = {frequency = 'normal', size = 'none', richness = 'normal'},
            desert = {frequency = 'normal', size = 'none', richness = 'normal'},
            dirt = {frequency = 'normal', size = 'normal', richness = 'normal'},
            sand = {frequency = 'normal', size = 'none', richness = 'normal'}
        },
    },
    -- sand only
    sand_only = {
        autoplace_controls = {
            grass = {frequency = 'normal', size = 'none', richness = 'normal'},
            desert = {frequency = 'normal', size = 'none', richness = 'normal'},
            dirt = {frequency = 'normal', size = 'none', richness = 'normal'},
            sand = {frequency = 'normal', size = 'normal', richness = 'normal'}
        },
    },
    -- will generate a world with only water (useful for maps that want full terrain control and no entities on the surface)
    waterworld = {
        autoplace_controls = {
            desert = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            dirt = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            grass = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            },
            sand = {
                frequency = 'normal',
                richness = 'normal',
                size = 'none'
            }
        },
        starting_points = {
            {
                x = 0,
                y = 0
            }
        },
    },
    -- will generate void except for a single tile
    void = {
        height = 1,
        width = 1
    },
    -- the default table is included as a reference but also to give the option of overwriting all user settings
    default = {
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
            cliff_elevation_0 = 10,
            cliff_elevation_interval = 10,
            name = 'cliff'
        },
        height = 2000000,
        peaceful_mode = false,
        starting_area = 'normal',
        terrain_segmentation = 'normal',
        water = 'normal',
        width = 2000000
    },
}
