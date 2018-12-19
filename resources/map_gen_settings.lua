--[[ The easiest way to create a preset is in factorio create a new world (vanilla, not scenario) and
    configure the settings you want. When you launch the game, you can run the following:
    /c
    local str = serpent.block(game.surfaces.nauvis.map_gen_settings)
    game.write_file('map_gen.lua', str)

    This will output a file with a table that you can add to this resources file or into your specific map.
    In either case, make sure to set seed to nil unless you want your map to be *exactly* the same each time.
]]
return {
    -- These settings are default except:
    -- cliffs disabled, enemy bases to high frequency and big size, and starting area to small
    no_cliffs = {
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
    -- no ores/oil, no cliffs, no water
    no_ores_cliffs_water = {
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
    -- no ores/oil, no cliffs, no water, no enemies
    no_ores_cliffs_water_enemies = {
        autoplace_controls = {
          coal = {
            frequency = "normal",
            richness = "normal",
            size = "none"
          },
          ["copper-ore"] = {
            frequency = "normal",
            richness = "normal",
            size = "none"
          },
          ["crude-oil"] = {
            frequency = "normal",
            richness = "normal",
            size = "none"
          },
          desert = {
            frequency = "normal",
            richness = "normal",
            size = "normal"
          },
          dirt = {
            frequency = "normal",
            richness = "normal",
            size = "normal"
          },
          ["enemy-base"] = {
            frequency = "normal",
            richness = "normal",
            size = "none"
          },
          grass = {
            frequency = "normal",
            richness = "normal",
            size = "normal"
          },
          ["iron-ore"] = {
            frequency = "normal",
            richness = "normal",
            size = "none"
          },
          sand = {
            frequency = "normal",
            richness = "normal",
            size = "normal"
          },
          stone = {
            frequency = "normal",
            richness = "normal",
            size = "none"
          },
          trees = {
            frequency = "normal",
            richness = "normal",
            size = "normal"
          },
          ["uranium-ore"] = {
            frequency = "normal",
            richness = "normal",
            size = "none"
          }
        },
        cliff_settings = {
          cliff_elevation_0 = 1024,
          cliff_elevation_interval = 10,
          name = "cliff"
        },
        height = 2000000,
        peaceful_mode = false,
        seed = nil,
        starting_area = "very-low",
        starting_points = {
          {
            x = 0,
            y = 0
          }
        },
        terrain_segmentation = "normal",
        water = "none",
        width = 2000000
      },
}
