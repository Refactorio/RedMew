--[[--

Welcome to the RedMew Scenario!
Thank you for your interest and we hope you will enjoy.

RedMew comes bundled with a boat-load of different map generators and some gamemodes to choose from.
This file chooses which map generator or gamemode will be used.

This file should be named `map_selection.lua` but you may find a `map_selection.sample.lua` instead.
The `map_selection.lua` file sets what map will be played when factorio creates a new save using the RedMew scenario.
Please keep `map_selection.sample.lua` as a backup, and make a copy named `map_selection.lua` with your own edits.
This way, you can always restore your configuration to the original if you run into trouble.

# Choosing your map

After this introduction is a list of map options, each on their own line.
All options, but one, starts with two dashes (--); this makes the line "commented out" / ignored.
In order to activate the map you want to use, find the line and "uncomment" it, by removing the two dashes.

The first uncommented line of code will determine what map to load.
So if you switch between them, don't forget to add two dashes in front of your previous choice.
Otherwise, you may end up loading the wrong choice again.

You can find previews for the maps in `/map_gen/data/.map_previews`.

# Presets

Some of the more advanced maps have presets that let you pick a variant.
These are grouped together in the list and should be pretty self-explanatory.

# Troubleshooting

This is a lua code file, and as such must be valid lua code.
You may accidentally cause the file to contain invalid code.
If this happens, you will most likely see an error message when starting the scenario.
This may look something like this:

```
__level__/map_gen/shared/map_loader.lua:1: __level__/map_selection.lua:1: unexpected symbol near ';'
stack traceback:
	[C]: in function 'require'
	__level__/map_gen/shared/map_loader.lua:1: in main chunk
	[C]: in function 'require'
	__level__/control.lua:20: in main chunk
```

You can either try to fix the problem by looking at the line that has the problem.
The line number is shown in the error as `__level__/map_selection.lua:{LineNumber}`.

Otherwise, we recommend to restore your `map_selection.lua` file from the sample file.
If the sample file is missing or unusable, you can find the latest version over at:
https://github.com/Refactorio/RedMew/blob/develop/map_selection.sample.lua

--]]--

--[[ RedMew's Crash Site ]]
--return require 'map_gen.maps.crash_site'
--return require 'map_gen.maps.crash_site.presets.UK'
--return require 'map_gen.maps.crash_site.presets.arrakis'
--return require 'map_gen.maps.crash_site.presets.desert'
--return require 'map_gen.maps.crash_site.presets.logistic_network_embargo'
--return require 'map_gen.maps.crash_site.presets.manhattan'
--return require 'map_gen.maps.crash_site.presets.no_bots'
--return require 'map_gen.maps.crash_site.presets.normal'
--return require 'map_gen.maps.crash_site.presets.only_construction_bots'
--return require 'map_gen.maps.crash_site.presets.only_personal_bots'
--return require 'map_gen.maps.crash_site.presets.raining_bullets'
--return require 'map_gen.maps.crash_site.presets.spiderless'
--return require 'map_gen.maps.crash_site.presets.steam_all_the_way'
--return require 'map_gen.maps.crash_site.presets.venice'
--return require 'map_gen.maps.crash_site.presets.world'

--[[ RedMew's Danger Ores ]]
--return require 'map_gen.maps.danger_ores'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_gradient'
--return require 'map_gen.maps.danger_ores.presets.terraforming_danger_ore'
--return require 'map_gen.maps.danger_ores.presets.danger_ore'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_3way'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_bob'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_bob_angel'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_bz'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_chessboard'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_circles'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_coal_maze'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_exotic_industries'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_exotic_industries_spiral'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_expanse'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_for_the_swarm'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_gradient'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_grid_factory'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_hub_spiral'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_industrial_revolution_3'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_industrial_revolution_3_grid_factory'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_krastorio2'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_landfill'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_lazy_one'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_normal_science'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_omnimatter'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_omnimatter_cages'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_one_direction'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_one_direction_wide'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_patches'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_permanence'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_poor_mans_coal_fields'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_pyfe'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_scrap'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_spiral'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_split'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_square'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_terraforming'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_x_cross'
--return require 'map_gen.maps.danger_ores.presets.danger_ore_xmas_tree'

--[[ RedMew's Diggy ]]
--return require 'map_gen.maps.diggy'
--return require 'map_gen.maps.diggy.presets.danger_ores'
--return require 'map_gen.maps.diggy.presets.danger_ores_BnB'

--[[ RedMew's Map Generators ]]
--return require 'map_gen.maps.1000x'
--return require 'map_gen.maps.antfarm'
--return require 'map_gen.maps.bacon_islands'
--return require 'map_gen.maps.beach'
--return require 'map_gen.maps.broken_web'
--return require 'map_gen.maps.christmas_tree_of_terror'
--return require 'map_gen.maps.concrete_jungle'
--return require 'map_gen.maps.connected_dots'
--return require 'map_gen.maps.contra_spiral'
--return require 'map_gen.maps.cookies'
--return require 'map_gen.maps.crash_site_desert'
--return require 'map_gen.maps.crash_site_manhattan'
--return require 'map_gen.maps.crash_site_UK'
--return require 'map_gen.maps.crash_site_venice'
--return require 'map_gen.maps.crash_site_world'
--return require 'map_gen.maps.crash_site'
--return require 'map_gen.maps.creation_of_adam'
--return require 'map_gen.maps.creation_of_adam2'
--return require 'map_gen.maps.danger_bobangels_ores'
--return require 'map_gen.maps.danger_bobs_ores'
--return require 'map_gen.maps.danger_ores'
--return require 'map_gen.maps.default'
--return require 'map_gen.maps.deprecated_borg_planet_v2'
--return require 'map_gen.maps.diagonal_ribbon'
--return require 'map_gen.maps.dickbutt'
--return require 'map_gen.maps.diggy'
--return require 'map_gen.maps.dimensions'
--return require 'map_gen.maps.dino_island'
--return require 'map_gen.maps.dna'
--return require 'map_gen.maps.donut'
--return require 'map_gen.maps.double_beach'
--return require 'map_gen.maps.factory_squared'
--return require 'map_gen.maps.fish_islands'
--return require 'map_gen.maps.fractal_balls'
--return require 'map_gen.maps.fruit_loops'
--return require 'map_gen.maps.gears'
--return require 'map_gen.maps.goat'
--return require 'map_gen.maps.goats_on_goats'
--return require 'map_gen.maps.GoT'
--return require 'map_gen.maps.grid_bot_islands'
--return require 'map_gen.maps.grid_islands_rotated'
--return require 'map_gen.maps.grid_islands'
--return require 'map_gen.maps.hearts'
--return require 'map_gen.maps.hilbert_water_trap'
--return require 'map_gen.maps.HilbertSandTrap'
--return require 'map_gen.maps.honeycomb'
--return require 'map_gen.maps.hub_spiral'
--return require 'map_gen.maps.infinite_mazes'
--return require 'map_gen.maps.island_resort'
--return require 'map_gen.maps.left'
--return require 'map_gen.maps.line_and_tree'
--return require 'map_gen.maps.line_and_trees'
--return require 'map_gen.maps.lines_and_balls'
--return require 'map_gen.maps.lines_and_squares'
--return require 'map_gen.maps.lines'
--return require 'map_gen.maps.loading_screen'
--return require 'map_gen.maps.maltease_crossings'
--return require 'map_gen.maps.manhattan'
--return require 'map_gen.maps.maori'
--return require 'map_gen.maps.maze_krastorio2'
--return require 'map_gen.maps.maze_with_rooms'
--return require 'map_gen.maps.maze'
--return require 'map_gen.maps.meteor_strike_data'
--return require 'map_gen.maps.meteor_strike'
--return require 'map_gen.maps.misc_stuff'
--return require 'map_gen.maps.mobius_strip'
--return require 'map_gen.maps.mona_lisa'
--return require 'map_gen.maps.north_america'
--return require 'map_gen.maps.pacman'
--return require 'map_gen.maps.plus'
--return require 'map_gen.maps.quadrants'
--return require 'map_gen.maps.rail_grid'
--return require 'map_gen.maps.right'
--return require 'map_gen.maps.ring_of_balls'
--return require 'map_gen.maps.rings_and_boxes'
--return require 'map_gen.maps.rocky_road'
--return require 'map_gen.maps.rotten_apples'
--return require 'map_gen.maps.safety_ores'
--return require 'map_gen.maps.sierpinski_carpet'
--return require 'map_gen.maps.snake_demo'
--return require 'map_gen.maps.snakey_swamp'
--return require 'map_gen.maps.snakier_swamp'
--return require 'map_gen.maps.solid_rock'
--return require 'map_gen.maps.space_race'
--return require 'map_gen.maps.spiral_crossings'
--return require 'map_gen.maps.spiral_of_spirals'
--return require 'map_gen.maps.spiral_shape'
--return require 'map_gen.maps.spiral_tri'
--return require 'map_gen.maps.spiral'
--return require 'map_gen.maps.spiral2'
--return require 'map_gen.maps.square_spiral_old'
--return require 'map_gen.maps.square_spiral'
--return require 'map_gen.maps.template'
--return require 'map_gen.maps.terra'
--return require 'map_gen.maps.terraforming_danger_ores'
--return require 'map_gen.maps.test'
--return require 'map_gen.maps.tetris'
--return require 'map_gen.maps.threaded_spirals'
--return require 'map_gen.maps.toxic_danger_ore_jungle'
--return require 'map_gen.maps.toxic_jungle'
--return require 'map_gen.maps.toxic_science_jungle'
--return require 'map_gen.maps.triangle_of_death'
--return require 'map_gen.maps.turkey'
--return require 'map_gen.maps.UK'
--return require 'map_gen.maps.up'
--return require 'map_gen.maps.vanilla'
--return require 'map_gen.maps.venice'
--return require 'map_gen.maps.void_gears'
--return require 'map_gen.maps.web'
--return require 'map_gen.maps.world_map_thanksgiving'
--return require 'map_gen.maps.world_map'
--return require 'map_gen.maps.x_shape'
--return require 'map_gen.maps.x-cross'

--[[ Finally, the following line provides a fallback if no choice has been un-commented above. ]]
return require 'map_gen.maps.default'
