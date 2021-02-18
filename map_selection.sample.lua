return require 'map_gen.maps.default'
--[[
    Replace the word default in the quotes above with the path and name of the map you want to play then save this file.
    Example: If you want to play beach, line 1 should look like:
    return require 'map_gen.maps.beach'
    If default is left in place, you will get a vanilla world.

    Some further examples, replace the first line of this file with one of these to choose a different map.
    For standard maps:
    return require 'map_gen.maps.connected_dots'
    return require 'map_gen.maps.grid_islands'
    return require 'map_gen.maps.double_beach'

    For some of our scenarios such as diggy, crash site and danger ores, they are more configurable and have presets. Look in the presets folder for each scenario you want to play, you can choose from them like this:
    return require 'map_gen.maps.danger_ores.presets.terraforming_danger_ore'
    return require 'map_gen.maps.danger_ores.presets.danger_ores_gradient'
    return require 'map_gen.maps.crash_site.presets.normal'
    return require 'map_gen.maps.crash_site.presets.desert'
    return require 'map_gen.maps.diggy.scenario'

    You can get the full list of maps by looking in map_gen/maps/
    Names of some popular maps:
    diggy
    crash_site
    beach
    connected_dots
    crosses
    danger_ores
    diagonal_ribbon
    double_beach
    fractal_balls
    fruit_loops
    grid_islands
    grid_islands_rotated
    line_and_tree
    line_and_trees
    lines_and_balls
    lines_and_squares
    maltease_crossings
    rotten_apples
    spiral_of_spirals
    tetris
    triangle_of_death
    void_gears
]]
