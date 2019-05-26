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
    -- the default table is included as a reference but also to give the option of overwriting all user settings
    default = {
        autoplace_controls = {
            coal = {
                frequency = 1,
                richness = 1,
                size = 1
            },
            ['copper-ore'] = {
                frequency = 1,
                richness = 1,
                size = 1
            },
            ['crude-oil'] = {
                frequency = 1,
                richness = 1,
                size = 1
            },
            ['enemy-base'] = {
                frequency = 1,
                richness = 1,
                size = 1
            },
            ['iron-ore'] = {
                frequency = 1,
                richness = 1,
                size = 1
            },
            stone = {
                frequency = 1,
                richness = 1,
                size = 1
            },
            trees = {
                frequency = 1,
                richness = 1,
                size = 1
            },
            ['uranium-ore'] = {
                frequency = 1,
                richness = 1,
                size = 1
            }
        },
        autoplace_settings = {},
        cliff_settings = {
            cliff_elevation_0 = 10,
            cliff_elevation_interval = 40,
            name = 'cliff',
            richness = 1
        },
        height = 2000000,
        peaceful_mode = false,
        property_expression_names = {},
        seed = nil,
        starting_area = 1,
        starting_points = {
            {
                x = 0,
                y = 0
            }
        },
        terrain_segmentation = 1,
        water = 1,
        width = 2000000
    },
    -- no enemies
    enemy_none = {
        autoplace_controls = {
            ['enemy-base'] = {
                frequency = 1,
                richness = 1,
                size = 0
            }
        }
    },
    -- high frequency and big size enemies
    enemy_high = {
        autoplace_controls = {
            ['enemy-base'] = {
                frequency = 1.41,
                richness = 1,
                size = 1.41
            }
        }
    },
    -- very high frequency and very big size enemies
    enemy_very_high = {
        autoplace_controls = {
            ['enemy-base'] = {
                frequency = 2,
                richness = 1,
                size = 2
            }
        }
    },
    -- no ores
    ore_none = {
        autoplace_controls = {
            coal = {
                frequency = 1,
                richness = 1,
                size = 0
            },
            ['copper-ore'] = {
                frequency = 1,
                richness = 1,
                size = 0
            },
            ['iron-ore'] = {
                frequency = 1,
                richness = 1,
                size = 0
            },
            stone = {
                frequency = 1,
                richness = 1,
                size = 0
            },
            ['uranium-ore'] = {
                frequency = 1,
                richness = 1,
                size = 0
            }
        }
    },
    -- no oil
    oil_none = {
        autoplace_controls = {
            ['crude-oil'] = {
                frequency = 1,
                richness = 1,
                size = 0
            }
        }
    },
    -- no ores, no oil
    ore_oil_none = {
        autoplace_controls = {
            coal = {
                frequency = 1,
                richness = 1,
                size = 0
            },
            ['copper-ore'] = {
                frequency = 1,
                richness = 1,
                size = 0
            },
            ['crude-oil'] = {
                frequency = 1,
                richness = 1,
                size = 0
            },
            ['iron-ore'] = {
                frequency = 1,
                richness = 1,
                size = 0
            },
            stone = {
                frequency = 1,
                richness = 1,
                size = 0
            },
            ['uranium-ore'] = {
                frequency = 1,
                richness = 1,
                size = 0
            }
        }
    },
    -- no water
    water_none = {
        autoplace_settings = {
            tile = {
                settings = {
                    ['deepwater'] = {frequency = 1, size = 0, richness = 1},
                    ['deepwater-green'] = {frequency = 1, size = 0, richness = 1},
                    ['water'] = {frequency = 1, size = 0, richness = 1},
                    ['water-green'] = {frequency = 1, size = 0, richness = 1},
                    ['water-mud'] = {frequency = 1, size = 0, richness = 1},
                    ['water-shallow'] = {frequency = 1, size = 0, richness = 1}
                }
            }
        }
    },
    -- very low water
    water_very_low = {
        terrain_segmentation = 0.5,
        water = 0.5
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
    -- cliffs to high frequency, big size
    cliff_high = {
        cliff_settings = {
            cliff_elevation_0 = 5,
            cliff_elevation_interval = 5,
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
    -- cliffs to very high frequency, very big size
    tree_none = {
        autoplace_controls = {
            trees = {
                frequency = 1,
                richness = 1,
                size = 0
            }
        }
    },
    -- cliffs to very high frequency, very big size
    tree_very_high = {
        autoplace_controls = {
            trees = {
                frequency = 2,
                richness = 2,
                size = 2
            }
        }
    },
    -- starting area to very low
    starting_area_very_low = {
        starting_area = 0
    },
    -- peaceful mode on
    peaceful_mode_on = {
        peaceful_mode = true
    },
    -- random seed, in case you need/want the seed to be unique from nauvis
    unique_seed = {
        seed = nil
    },
    -- grass1 only (no water, you will need to add enabled_water if you want water)
    grass1_only = {
        autoplace_settings = {
            tile = {
                treat_missing_as_default = false,
                settings = {
                    ['grass-1'] = {frequency = 1, size = 1, richness = 1}
                }
            }
        }
    },
    -- grass only (no water, you will need to add enabled_water if you want water)
    grass_only = {
        autoplace_settings = {
            tile = {
                treat_missing_as_default = false,
                settings = {
                    ['grass-1'] = {frequency = 1, size = 1, richness = 1},
                    ['grass-2'] = {frequency = 1, size = 1, richness = 1},
                    ['grass-3'] = {frequency = 1, size = 1, richness = 1},
                    ['grass-4'] = {frequency = 1, size = 1, richness = 1}
                }
            }
        }
    },
    -- desert only (no water, you will need to add enabled_water if you want water)
    desert_only = {
        autoplace_settings = {
            tile = {
                treat_missing_as_default = false,
                settings = {
                    ['red-desert-0'] = {frequency = 1, size = 1, richness = 1},
                    ['red-desert-1'] = {frequency = 1, size = 1, richness = 1},
                    ['red-desert-2'] = {frequency = 1, size = 1, richness = 1},
                    ['red-desert-3'] = {frequency = 1, size = 1, richness = 1}
                }
            }
        }
    },
    -- dirt only (no water, you will need to add enabled_water if you want water)
    dirt_only = {
        autoplace_settings = {
            tile = {
                treat_missing_as_default = false,
                settings = {
                    ['dirt-1'] = {frequency = 1, size = 1, richness = 1},
                    ['dirt-2'] = {frequency = 1, size = 1, richness = 1},
                    ['dirt-3'] = {frequency = 1, size = 1, richness = 1},
                    ['dirt-4'] = {frequency = 1, size = 1, richness = 1},
                    ['dirt-5'] = {frequency = 1, size = 1, richness = 1},
                    ['dirt-6'] = {frequency = 1, size = 1, richness = 1},
                    ['dirt-7'] = {frequency = 1, size = 1, richness = 1}
                }
            }
        }
    },
    -- sand only (no water, you will need to add enabled_water if you want water)
    sand_only = {
        autoplace_settings = {
            tile = {
                treat_missing_as_default = false,
                settings = {
                    ['sand-1'] = {frequency = 1, size = 1, richness = 1},
                    ['sand-2'] = {frequency = 1, size = 1, richness = 1},
                    ['sand-3'] = {frequency = 1, size = 1, richness = 1}
                }
            }
        }
    },
    -- adds water to *_only maps
    enable_water = {
        autoplace_settings = {
            tile = {
                settings = {
                    ['deepwater'] = {frequency = 1, size = 1, richness = 1},
                    ['deepwater-green'] = {frequency = 1, size = 1, richness = 1},
                    ['water'] = {frequency = 1, size = 1, richness = 1},
                    ['water-green'] = {frequency = 1, size = 1, richness = 1},
                    ['water-mud'] = {frequency = 1, size = 1, richness = 1},
                    ['water-shallow'] = {frequency = 1, size = 1, richness = 1}
                }
            }
        }
    },
    -- will generate a world with only water (useful for maps that want full terrain control and no entities on the surface) (non-functional in 0.17)
    waterworld = {
        autoplace_settings = {
            tile = {
                treat_missing_as_default = false,
                settings = {
                    ['deepwater'] = {frequency = 1, size = 1, richness = 1},
                    ['deepwater-green'] = {frequency = 1, size = 1, richness = 1},
                    ['water'] = {frequency = 1, size = 1, richness = 1},
                    ['water-green'] = {frequency = 1, size = 1, richness = 1},
                    ['water-mud'] = {frequency = 1, size = 1, richness = 1},
                    ['water-shallow'] = {frequency = 1, size = 1, richness = 1}
                }
            }
        }
    },
    -- creates a 1x1 world border, this will prevent chunks from being generated
    void = {
        height = 1,
        width = 1
    },
    -- The starting area plateau surrounded by an endless ocean
    starting_plateau = {
        property_expression_names = {
            elevation = '0_17-starting-plateau'
        }
    }
}
